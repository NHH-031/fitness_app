# CHƯƠNG 3. CÁC KỸ THUẬT LẬP TRÌNH ANDROID TRONG ỨNG DỤNG

Chương 3 trình bày các kỹ thuật lập trình hệ thống Android trong ứng dụng Fitness Tracker. Để theo dõi sức khỏe liên tục, ứng dụng phải vận hành bền bỉ dưới nền, tương tác trực tiếp với cảm biến phần cứng, duy trì lịch báo thức chính xác và đồng bộ dữ liệu giữa Native Kotlin và Flutter qua Platform Channel. Nhóm phân tích nguyên lý hoạt động, cấu trúc mã nguồn, giải pháp xử lý sự cố hệ điều hành và minh chứng thực nghiệm bằng các công cụ chuyên dụng.

---

## 3.1. Dịch vụ chạy nền Foreground Service và cảm biến đếm bước chân

Từ Android 8.0 (API level 26), hệ điều hành áp dụng cơ chế *Low Memory Killer* (LMK) và giới hạn thực thi nền (*Background Execution Limits*). Khi người dùng rời ứng dụng hoặc tắt màn hình, các dịch vụ nền thông thường sẽ bị dừng sau vài phút. Để đếm bước chân liên tục trong ngày, nhóm triển khai kỹ thuật *Foreground Service* kết hợp cảm biến phần cứng chuyên dụng.

### 3.1.1. Kiến trúc StepCounterService và kiểu dịch vụ FOREGROUND_SERVICE_HEALTH

Dịch vụ chạy nền được hiện thực qua lớp `StepCounterService` kế thừa từ `android.app.Service` và triển khai `SensorEventListener`, khai báo `android:exported="false"` trong `AndroidManifest.xml` nhằm ngăn chặn truy cập trái phép.

Từ Android 14 (API level 34), Google yêu cầu mọi dịch vụ chạy nền phải chỉ định loại hình dịch vụ (*Foreground Service Type*) và khai báo quyền tương ứng. Nếu gọi `startForeground()` mà thiếu khai báo này, hệ thống sẽ ném ngoại lệ `MissingForegroundServiceTypeException` và dừng tiến trình. Nhóm cấu hình kiểu dịch vụ chuyên biệt cho sức khỏe:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH" />

<service
    android:name=".StepCounterService"
    android:foregroundServiceType="health"
    android:exported="false" />
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:4-5,69-72`)

Vòng đời của `StepCounterService` khởi đầu tại `onCreate()` với ba tác vụ:
1. Tạo kênh thông báo (*Notification Channel*) mức ưu tiên `IMPORTANCE_LOW` không rung, không chuông.
2. Nâng cấp tiến trình lên trạng thái tiền đình bằng `startForeground(NOTIFICATION_ID, notification)` gắn với thông báo thường trực (*Ongoing Notification*), nâng độ ưu tiên của tiến trình để giảm nguy cơ bị LMK thu hồi.
3. Nhận tham chiếu `SensorManager` từ hệ thống và đăng ký lắng nghe cảm biến đếm bước.

Tại `onStartCommand()`, dịch vụ trả về cờ `START_STICKY`. Khi hệ thống thu hồi bộ nhớ, Android sẽ tự động khởi động lại `StepCounterService` ngay khi tài nguyên phục hồi, bảo đảm việc đếm bước chân không bị gián đoạn.

### 3.1.2. Cơ chế cảm biến TYPE_STEP_COUNTER, thuật toán baseline và reboot-offset

Phần cứng theo dõi bước chân trên Android cung cấp hai loại cảm biến:
- `Sensor.TYPE_STEP_DETECTOR`: Phát sự kiện mỗi khi người dùng đi một bước (giá trị luôn là `1.0`), khiến CPU phải thức dậy liên tục, tiêu hao pin.
- `Sensor.TYPE_STEP_COUNTER`: Trả về một giá trị duy nhất là **tổng số bước chân tích lũy từ thời điểm thiết bị khởi động lại lần gần nhất**, liên tục tăng dần và không tự đặt lại về 0 cho đến khi tắt nguồn máy.

Nhóm chọn `Sensor.TYPE_STEP_COUNTER` để tiết kiệm pin. Tuy nhiên, cơ chế tích lũy này đặt ra hai bài toán:
1. Xác định số bước trong ngày: Người dùng chỉ cần số bước từ 00:00:00 của ngày hiện tại, trong khi phần cứng đếm dồn qua nhiều ngày.
2. Xử lý khi thiết bị khởi động lại (Reboot Offset): Khi tắt nguồn máy, giá trị cảm biến bị xóa về 0. Nếu chỉ trừ mốc đầu ngày, số bước tính toán sẽ bị sai lệch âm hoặc mất số bước đã đi trước khi tắt máy.

Nhóm thiết kế thuật toán **Mốc cơ sở kết hợp bù trừ khởi động lại** (*Baseline & Reboot-Offset Algorithm*) trong hàm `processNativeHardwareSteps()`, sử dụng ba biến lưu trong `SharedPreferences`:
- `step_baseline_date`: Chuỗi ngày hiện tại (`yyyy-MM-dd`).
- `step_baseline_hardware`: Mốc số bước phần cứng ghi nhận lần đầu trong ngày.
- `step_reboot_offset`: Số bước chân tích lũy trong ngày trước các lần khởi động lại máy.

Công thức tính số bước chân thực tế trong ngày (`today_steps`):

$$\text{today\_steps} = \text{reboot\_offset} + (\text{hardware\_steps} - \text{baseline})$$

Thuật toán phân nhánh theo ba trường hợp:
- **Ngày mới hoặc lần đầu chạy**: Khi ngày hệ thống khác `step_baseline_date` hoặc `baseline == -1L`, mốc cơ sở được gán bằng giá trị phần cứng hiện tại (`baseline = hardwareSteps`), `rebootOffset` đặt về 0, và số bước trong ngày là 0.
- **Khởi động lại máy trong ngày**: Nhận biết khi giá trị phần cứng nhỏ hơn mốc cơ sở (`hardwareSteps < baseline`). Số bước đi được trước khi tắt máy chính là giá trị `today_steps` đã lưu. Thuật toán gán `rebootOffset = previousToday` và cập nhật mốc cơ sở mới `baseline = hardwareSteps`.
- **Hoạt động bình thường**: Số bước phát sinh thêm là `hardwareSteps - baseline`. Khi cộng với `rebootOffset`, thuật toán cho ra chính xác tổng số bước chân trong ngày.

Đoạn mã Kotlin triển khai thuật toán:

```kotlin
if (savedDate != todayStr || baseline == -1L) {
    baseline = hardwareSteps.toLong()
    rebootOffset = 0L
    prefs.edit().putString("flutter.step_baseline_date", todayStr)
        .putLong("flutter.step_baseline_hardware", baseline)
        .putLong("flutter.step_reboot_offset", 0L).putLong("flutter.today_steps", 0L).apply()
    return 0
}
if (hardwareSteps < baseline) {
    rebootOffset = getSafeLong(prefs, "flutter.today_steps", 0L)
    baseline = hardwareSteps.toLong()
    prefs.edit().putLong("flutter.step_baseline_hardware", baseline)
        .putLong("flutter.step_reboot_offset", rebootOffset).apply()
}
val calculated = (rebootOffset + (hardwareSteps - baseline)).coerceAtLeast(0L).toInt()
```
(Nguồn: `android/app/src/main/kotlin/com/example/fitness_tracker/StepCounterService.kt:105-127`)

Sau khi tính toán, dịch vụ lưu kết quả vào `FlutterSharedPreferences`, cập nhật thông báo tiền đình và phát Intent nội bộ để MainActivity chuyển tiếp lên giao diện người dùng nếu ứng dụng đang mở.

![Hình 3.1: Quy trình thu thập và tính toán bước chân trong StepCounterService](img/so-do-step-counter.png)

Thông báo của dịch vụ được duy trì trên thanh trạng thái, hiển thị số bước trong ngày dạng "Hôm nay: N / 10000 bước (x%)" và được cập nhật sau mỗi lần dịch vụ nhận dữ liệu cảm biến:

![Hình 3.2: Thông báo liên tục của dịch vụ chạy nền StepCounterService](img/chup-step-notification.png)
> CHỤP: Notification của StepCounterService trên thanh thông báo / hiển thị số bước chân trong ngày / khởi chạy ứng dụng và bật đếm bước chân.

---

## 3.2. Tự khởi động và khôi phục dịch vụ với BroadcastReceiver

Khi thiết bị khởi động lại, các tiến trình trong RAM bị giải phóng. Để khôi phục hoạt động theo dõi bước chân mà không cần người dùng mở ứng dụng thủ công, nhóm triển khai lớp `BootReceiver` kế thừa từ `BroadcastReceiver`, đăng ký tĩnh trong `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<receiver
    android:name=".BootReceiver"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:7,84-94`)

Bộ lọc Intent Filter lắng nghe bốn hành động phát sóng:
1. `android.intent.action.BOOT_COMPLETED`: Phát ra khi hệ thống khởi động xong và người dùng mở khóa màn hình lần đầu.
2. `android.intent.action.MY_PACKAGE_REPLACED`: Phát ra khi ứng dụng được cập nhật phiên bản mới.
3. `android.intent.action.QUICKBOOT_POWERON` và `com.htc.intent.action.QUICKBOOT_POWERON`: Phát ra trên các thiết bị hỗ trợ khởi động nhanh.

Khi nhận tín hiệu trong `onReceive()`, `BootReceiver` khởi động `StepCounterService`:

```kotlin
val action = intent.action
if (action == Intent.ACTION_BOOT_COMPLETED ||
    action == Intent.ACTION_MY_PACKAGE_REPLACED ||
    action == "android.intent.action.QUICKBOOT_POWERON" ||
    action == "com.htc.intent.action.QUICKBOOT_POWERON"
) {
    val serviceIntent = Intent(context, StepCounterService::class.java)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(serviceIntent)
    } else {
        context.startService(serviceIntent)
    }
}
```
(Nguồn: `android/app/src/main/kotlin/com/example/fitness_tracker/BootReceiver.kt:12-25`)

Từ Android 8.0, việc gọi `startService()` từ môi trường nền bị cấm. Mã nguồn sử dụng `startForegroundService()`. Hệ điều hành cấp khoảng 5 giây để dịch vụ hoàn tất lệnh `startForeground()`. Dịch vụ đọc lại các mốc bù trừ từ `SharedPreferences` và tiếp tục thu thập dữ liệu cảm biến.

Lưu ý thực tế trên HyperOS: khi thử cập nhật ứng dụng qua `adb install -r` (phát `MY_PACKAGE_REPLACED`) trong lúc chưa bật quyền *Tự khởi chạy* (*Autostart*), dịch vụ không tự chạy lại cho đến khi người dùng mở ứng dụng. Điều này phù hợp với cơ chế Autostart của HyperOS/MIUI vốn chặn ứng dụng tự khởi động từ broadcast hệ thống; nhóm chưa kiểm tra trường hợp khởi động lại máy (`BOOT_COMPLETED`).

---

## 3.3. Tiện ích màn hình chính App Widget

Tiện ích màn hình chính (*App Widget*) cho phép người dùng quan sát chỉ số sức khỏe ngay trên màn hình chính mà không cần mở ứng dụng. Nhóm xây dựng widget kích thước 4x2 hiển thị số bước chân (chỉ tiêu 10.000 bước) và lượng nước uống (chỉ tiêu 8 cốc).

### 3.3.1. Kiến trúc AppWidgetProvider và cơ chế RemoteViews

Widget được quản lý bởi lớp `FitnessAppWidgetProvider` kế thừa từ `AppWidgetProvider`. Do widget hiển thị trong không gian tiến trình của Launcher, ứng dụng sử dụng cơ chế `RemoteViews` — gói mô tả giao diện chứa định danh layout và các chỉ thị cập nhật giao diện được tuần tự hóa qua IPC.

Cấu hình widget được khai báo trong `res/xml/fitness_app_widget_info.xml`:

```xml
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="90dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/fitness_app_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
```
(Nguồn: `android/app/src/main/res/xml/fitness_app_widget_info.xml:2-10`)

Thuộc tính `updatePeriodMillis` được đặt là 1.800.000 ms (30 phút) — tần suất cập nhật định kỳ tối thiểu theo quy định hệ điều hành để bảo vệ dung lượng pin. Hai thuộc tính `targetCellWidth`/`targetCellHeight` (Android 12+) gợi ý launcher đặt widget ở kích thước 4×2 ô.

Do layout được Launcher dựng lại trong tiến trình khác, `RemoteViews` chỉ chấp nhận một tập lớp giao diện xác định (`FrameLayout`, `LinearLayout`, `RelativeLayout`, `TextView`, `ImageView`, `ProgressBar`, `Button`…). Lớp `android.view.View` thuần không nằm trong danh sách này: nếu layout chứa `<View>`, Launcher ném `InflateException: Class not allowed to be inflated android.view.View` và hiển thị "Không thể tải tiện ích". Vì vậy, các đường kẻ phân cách trong `fitness_app_widget.xml` được dựng bằng `FrameLayout` có màu nền:

```xml
<!-- RemoteViews không cho phép android.view.View, nên đường kẻ dùng FrameLayout có màu nền -->
<FrameLayout
    android:layout_width="match_parent"
    android:layout_height="1dp"
    android:layout_marginTop="8dp"
    android:layout_marginBottom="10dp"
    android:background="#22FFFFFF" />
```
(Nguồn: `android/app/src/main/res/layout/fitness_app_widget.xml:36-43`)

### 3.3.2. Cập nhật dữ liệu từ SharedPreferences và điều hướng với PendingIntent

Ngoài chu kỳ 30 phút của hệ thống, widget còn được cập nhật khi người dùng thao tác trong ứng dụng. Khi dữ liệu thay đổi, Flutter gọi MethodChannel `updateWidget` để kích hoạt phương thức tĩnh `FitnessAppWidgetProvider.updateAllWidgets()`.

Phương thức này đọc giá trị số bước và số cốc nước mới nhất từ `FlutterSharedPreferences`, cập nhật `RemoteViews` và gắn `PendingIntent` lên vùng chứa widget để mở `MainActivity` khi người dùng nhấn vào:

```kotlin
val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
val steps = prefs.getLong("flutter.today_steps", 0L).toInt()
val water = prefs.getLong("flutter.water_cups_today", 0L).toInt()
val stepsFormatted = DecimalFormat("#,###").format(steps)

val views = RemoteViews(context.packageName, R.layout.fitness_app_widget)
views.setTextViewText(R.id.widget_steps_text, "$stepsFormatted / 10.000")
views.setTextViewText(R.id.widget_water_text, "$water / 8 cốc")

val intent = Intent(context, MainActivity::class.java).apply {
    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
}
val pendingIntent = PendingIntent.getActivity(
    context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
)
views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
```
(Nguồn: `android/app/src/main/kotlin/com/example/fitness_tracker/FitnessAppWidgetProvider.kt:30-49`)

Cờ `PendingIntent.FLAG_IMMUTABLE` được khai báo bắt buộc theo tiêu chuẩn bảo mật từ Android 12 (API level 31), ngăn chặn việc sửa đổi Intent trước khi thực thi.

![Hình 3.3: Widget tiện ích của ứng dụng trên màn hình chính Android](img/chup-app-widget.png)
> CHỤP: Màn hình Home của Android có FitnessAppWidget / hiển thị số bước chân và lượng nước uống cập nhật / thêm widget từ menu tiện ích ra màn hình Home.

---

## 3.4. Hệ thống thông báo và lập lịch báo thức chính xác (Notification & AlarmManager)

Hệ thống thông báo trong ứng dụng đảm nhận hai nhiệm vụ: nhắc nhở người dùng uống nước đúng giờ và theo dõi thời gian nghỉ giữa các hiệp tập luyện (*Workout Session*).

### 3.4.1. Quản lý Notification Channel theo chuẩn Android 8.0+

Từ Android 8.0, mọi thông báo bắt buộc phải được gắn vào một Kênh thông báo (*Notification Channel*). Nhóm thiết lập ba kênh:
1. `StepCounterChannel`: Mức ưu tiên `IMPORTANCE_LOW`, không phát âm thanh, không rung, phục vụ thông báo thường trực của `StepCounterService`.
2. `water_reminder_channel`: Mức ưu tiên `Importance.max` (cấu hình qua `flutter_local_notifications`), bật rung (`enableVibration = true`) và chuông báo, nhắc nhở bổ sung nước.
3. `rest_timer_channel`: Mức ưu tiên `Importance.high`, cấu hình `onlyAlertOnce = true` để khi cập nhật từng giây đếm ngược, thông báo không phát âm thanh hay rung liên tục.

### 3.4.2. Lập lịch báo thức chính xác với AlarmManager và quyền SCHEDULE_EXACT_ALARM

Để nhắc nhở uống nước hằng ngày bắt đầu từ 08:00 theo chu kỳ 1, 2 hoặc 3 giờ (mặc định 2 giờ: 7 mốc 08:00–20:00; chu kỳ 1 giờ: 14 mốc 08:00–21:00), ứng dụng cần đánh thức hệ thống đúng mốc thời gian. Các cơ chế như `WorkManager` chỉ hỗ trợ lịch trình linh hoạt và bị hoãn lại khi gom nhóm tác vụ.

Nhóm sử dụng cơ chế báo thức chính xác qua plugin `flutter_local_notifications` kết hợp thư viện `timezone`. Lệnh `zonedSchedule` được cấu hình chế độ `AndroidScheduleMode.exactAllowWhileIdle`, tương ứng với API native `AlarmManager.setExactAndAllowWhileIdle()`. API này phát tín hiệu báo thức đúng giờ ngay cả khi thiết bị đang ở chế độ ngủ sâu (*Doze mode*):

```dart
await _notificationsPlugin.zonedSchedule(
  id: _waterNotificationId + count,
  title: 'Time to drink water! 💧',
  body: 'Drink a glass of water (250ml) at $hour:00 to keep your body energized.',
  scheduledDate: scheduledDate,
  notificationDetails: _getNotificationDetails(),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time,
);
```
(Nguồn: `lib/services/notification_service.dart:152-160`)

Kiểm tra trên thiết bị bằng `adb shell dumpsys alarm` cho thấy các lịch nhắc được đăng ký với loại `RTC_WAKEUP`, `window=0` (thời điểm chính xác) và cờ cho phép kích hoạt khi máy ở chế độ Doze. Mỗi lịch dùng một định danh riêng trong dải `1001`–`1020`; thông báo gửi ngay và thông báo thử nghiệm dùng định danh nằm ngoài dải này nên không ghi đè lịch nhắc hằng ngày.

Từ Android 12 (API level 31), ứng dụng khai báo quyền `SCHEDULE_EXACT_ALARM` và `USE_EXACT_ALARM` trong Manifest:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:8-9`)

### 3.4.3. Thông báo đếm ngược nghỉ hiệp với thanh tiến trình trực quan

Trong phân hệ tập luyện, khi hoàn thành hiệp nâng tạ, ứng dụng kích hoạt đồng hồ đếm ngược thời gian nghỉ (mặc định 60 giây, người dùng có thể cộng thêm 15 giây hoặc bỏ qua). Nếu người dùng tắt màn hình hoặc chuyển sang ứng dụng khác, thông báo trên `rest_timer_channel` hiển thị tiến độ với các thuộc tính:
- `ongoing: true`: Giữ thông báo cố định trên khay hệ thống.
- `showProgress: true`, `maxProgress: totalSeconds`, `progress: currentProgress`: Hiển thị thanh tiến trình đồ họa co ngắn dần theo từng giây.
- Khi hết giờ nghỉ (`remainingSeconds == 0`), ứng dụng hủy thông báo đếm ngược và phát thông báo kết thúc có rung và chuông để người dùng bước vào hiệp tiếp theo.

![Hình 3.4: Thông báo đếm ngược nghỉ hiệp với thanh tiến trình trên khay hệ thống](img/chup-rest-timer-notification.png)

---

## 3.5. Tối ưu hóa năng lượng và cơ chế Doze Mode của Android

Ứng dụng theo dõi vận động liên tục cần tối ưu hóa năng lượng để tránh làm hao pin thiết bị. Nhóm kết hợp hai giải pháp kỹ thuật nhằm giảm mức tiêu thụ điện năng.

### 3.5.1. Nguyên lý Sensor Batching giúp CPU ngủ sâu

Cảm biến đếm bước `TYPE_STEP_COUNTER` được điều khiển bởi bộ vi xử lý tín hiệu phụ năng lượng thấp (*Sensor Hub*) độc lập với CPU chính, đi kèm bộ đệm phần cứng FIFO.

Nếu đăng ký lắng nghe cảm biến bằng phương thức thông thường, mỗi khi có bước chân, hệ thống sẽ phát ngắt phần cứng đánh thức CPU chính, khiến CPU không thể vào trạng thái ngủ sâu (*Deep Sleep*). Nhóm áp dụng kỹ thuật **Gộp mẫu cảm biến** (*Sensor Batching*) bằng cách truyền tham số `maxReportLatency`:

```kotlin
stepSensor?.let {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
        sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL, 10000000)
    } else {
        sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
    }
}
```
(Nguồn: `android/app/src/main/kotlin/com/example/fitness_tracker/StepCounterService.kt:41-48`)

Giá trị `10000000` micro giây (10 giây) chỉ định cho Android Sensor HAL lưu trữ tạm thời các sự kiện bước chân trong bộ đệm FIFO của phần cứng. Trong suốt 10 giây đó, CPU của điện thoại duy trì trạng thái ngủ sâu. Khi bộ đệm đầy hoặc hết 10 giây, bộ điều khiển cảm biến mới phát một ngắt duy nhất đánh thức CPU để chuyển giao hàng loạt sự kiện, giúp giảm tần suất đánh thức CPU.

### 3.5.2. Vượt rào Doze Mode và chính sách tiết kiệm pin trên các bản tùy biến OEM

Từ Android 6.0 (API level 23), Google giới thiệu cơ chế **Doze Mode**. Khi thiết bị không cắm sạc, màn hình tắt và nằm yên, hệ điều hành sẽ đưa thiết bị vào chế độ Doze sâu: ngắt kết nối mạng, hoãn tác vụ nền và hạn chế hoạt động của dịch vụ. Trên các thiết bị tùy biến như Xiaomi (HyperOS / MIUI) hay Samsung (OneUI), chính sách quản lý pin của nhà sản xuất thường dừng tiến trình nền chặt chẽ hơn tiêu chuẩn gốc.

Để giảm nguy cơ dịch vụ bị dừng, nhóm triển khai tính năng kiểm tra và yêu cầu người dùng đưa ứng dụng vào danh sách miễn trừ tối ưu hóa pin (*Battery Optimization Whitelist*). Trong `MainActivity.kt`, ứng dụng kiểm tra trạng thái miễn trừ qua `PowerManager.isIgnoringBatteryOptimizations()`. Nếu chưa được miễn trừ, ứng dụng gọi Intent `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`:

```kotlin
val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
    data = Uri.parse("package:$packageName")
}
startActivity(intent)
```
(Nguồn: `android/app/src/main/kotlin/com/example/fitness_tracker/MainActivity.kt:58-61`)

Trên Android gốc, Intent này mở trực tiếp hộp thoại hệ thống cho phép người dùng cấp quyền. Trên thiết bị thử nghiệm chạy HyperOS, Intent được chuyển tới trang *Battery details* của MIUI, nơi người dùng chọn chế độ "No restrictions" thay cho chế độ mặc định "Battery saver (recommended)". Ứng dụng đã khai báo quyền tương ứng trong Manifest:

```xml
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:14`)

Khi nằm trong danh sách miễn trừ, dịch vụ được hệ điều hành ưu tiên duy trì trong bộ nhớ và tiếp nhận sự kiện cảm biến ngay cả khi thiết bị vào chu kỳ Doze sâu.

![Hình 3.5: Trang thiết lập pin của HyperOS mở từ yêu cầu miễn trừ tối ưu hóa pin](img/chup-hyperos-battery.png)

---

## 3.6. Cầu nối Platform Channel và đồng bộ dữ liệu dùng chung

Fitness Tracker kết hợp giao diện Flutter và các thành phần hệ thống Android Native. Hai tầng này giao tiếp qua Platform Channel và đồng bộ dữ liệu qua bộ nhớ cục bộ.

### 3.6.1. Kiến trúc MethodChannel và EventChannel

Mô hình giao tiếp giữa Flutter Engine và tầng Native được tổ chức qua hai kênh:
1. **MethodChannel (`com.example.fitness_tracker/service`)**: Hoạt động theo cơ chế gọi hàm có phản hồi (*Request - Response*). Kênh này cho phép tầng Dart gửi các lệnh điều khiển xuống Android Native: `startService` (khởi chạy dịch vụ đếm bước), `isIgnoringBatteryOptimizations` (kiểm tra trạng thái pin), `requestIgnoreBatteryOptimizations` (mở hộp thoại xin quyền pin) và `updateWidget` (cập nhật widget màn hình chính).
2. **EventChannel (`com.example.fitness_tracker/steps`)**: Hoạt động theo cơ chế luồng sự kiện một chiều (*Event Stream*). Khi widget hiển thị bước chân được gắn vào cây giao diện, nó lắng nghe luồng phát sóng qua `receiveBroadcastStream()`.

Tại tầng Kotlin trong `MainActivity.kt`, nhóm triển khai `EventChannel.StreamHandler`. Khi Flutter bắt đầu lắng nghe (`onListen`), `MainActivity` đăng ký bộ thu sóng động `stepReceiver` lắng nghe Intent `ACTION_STEP_UPDATE`. Từ Android 13 (API level 33), hệ điều hành yêu cầu chỉ định cờ xuất khẩu cho bộ thu sóng động. Nhóm áp dụng cờ `Context.RECEIVER_NOT_EXPORTED` để chỉ các thành phần cùng gói ứng dụng mới có thể gửi dữ liệu:

```kotlin
override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    val filter = IntentFilter(StepCounterService.ACTION_STEP_UPDATE)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        registerReceiver(stepReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    } else {
        registerReceiver(stepReceiver, filter)
    }
}
```
(Nguồn: `android/app/src/main/kotlin/com/example/fitness_tracker/MainActivity.kt:86-94`)

Khi `StepCounterService` ghi nhận bước chân mới, nó phát Intent mang theo số bước. `stepReceiver` tiếp nhận dữ liệu và gửi vào `eventSink.success(steps)`, truyền qua BinaryMessenger để giao diện cập nhật vòng tròn tiến độ.

### 3.6.2. Cơ chế đồng bộ dữ liệu hai chiều qua SharedPreferences và phân tích rủi ro tranh chấp

Để dữ liệu bước chân và nước uống luôn sẵn sàng cho App Widget và `StepCounterService` truy cập khi Flutter Engine chưa khởi chạy, nhóm sử dụng tệp cấu hình nguyên bản của Android mang tên `"FlutterSharedPreferences"` làm vùng nhớ trung gian:
- **Tầng Native đọc/ghi**: `StepCounterService` và `FitnessAppWidgetProvider` truy xuất qua `context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)` với các khóa: `flutter.today_steps`, `flutter.water_cups_today`.
- **Tầng Dart đọc/ghi**: `StepRepository` và `StorageService` của Flutter đọc và ghi vào cùng tệp XML này tại đường dẫn `/data/data/com.nhh031.fitness_tracker/shared_prefs/FlutterSharedPreferences.xml`.

![Hình 3.6: Kiến trúc cầu nối Platform Channel và dữ liệu dùng chung](img/so-do-platform-bridge.png)

#### Phân tích rủi ro tranh chấp dữ liệu (Race Condition)
Cơ chế `SharedPreferences` của Android không hỗ trợ khóa tiến trình đồng thời (*Inter-Process Locking*). Trong `StepCounterService.kt:129-131`, mã Kotlin gọi `apply()` để lưu số bước mới sau mỗi chu kỳ cảm biến. Cùng thời điểm, tại `step_repository.dart`, tầng Flutter cũng có thể ghi dữ liệu khi người dùng lưu mốc vận động. Do hai tiến trình/luồng ghi độc lập không có cơ chế khóa tương hỗ (*Mutex*), nguy cơ ghi đè làm mất mốc bước chân có thể phát sinh nếu các thao tác ghi diễn ra đồng thời. Trong các giai đoạn tiếp theo, việc chuyển đổi vùng nhớ dùng chung sang `Room Database` kết hợp `ContentProvider` sẽ giúp đảm bảo tính toàn vẹn dữ liệu tốt hơn.

---

## 3.7. Tích hợp chuẩn dữ liệu sức khỏe Android Health Connect

Từ Android 14 (API level 34), Google tích hợp **Health Connect** vào lõi hệ điều hành nhằm quản lý tập trung dữ liệu sức khỏe và quyền riêng tư trên thiết bị. Trên các thiết bị chạy Android 8.0 đến Android 13, người dùng có thể cài đặt Health Connect từ Google Play Store.

### 3.7.1. Khai báo Package Visibility và cấp quyền Health Connect

Để ứng dụng tương tác được với Health Connect trên Android 11+ (API level 30), ứng dụng khai báo quyền hiển thị gói cài đặt (*Package Visibility*) trong thẻ `<queries>` của Manifest:

```xml
<queries>
    <package android:name="com.google.android.apps.healthdata" />
    <intent>
        <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
    </intent>
</queries>
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:112-117`)

Đồng thời, ứng dụng khai báo các quyền đọc dữ liệu sức khỏe:

```xml
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
<uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.READ_SLEEP"/>
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:16-20`)

Theo hướng dẫn tích hợp Health Connect, trên Android 14 trở lên ứng dụng cần khai báo màn hình giải trình quyền. Ứng dụng đáp ứng yêu cầu này bằng một `activity-alias` trỏ tới `MainActivity`, nhận Intent `VIEW_PERMISSION_USAGE` thuộc nhóm `HEALTH_PERMISSIONS`:

```xml
<activity-alias
    android:name="ViewPermissionUsageActivity"
    android:exported="true"
    android:targetActivity=".MainActivity"
    android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
    <intent-filter>
        <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
        <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
    </intent-filter>
</activity-alias>
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:53-62`)

Theo chính sách của Google, ứng dụng khai báo Intent Filter `ACTION_SHOW_PERMISSIONS_RATIONALE` trong `MainActivity`. Khi người dùng xem phần giải trình quyền trong Cài đặt của Health Connect, hệ thống sẽ mở màn hình giải thích mục đích thu thập dữ liệu của ứng dụng.

### 3.7.2. Cơ chế đồng bộ chỉ số sức khỏe trong ứng dụng

Lớp `HealthSyncService` phụ trách kết nối với Health Connect qua plugin `health`. Khi người dùng chọn "Kết nối Health Connect":
1. Ứng dụng kiểm tra tính khả dụng bằng `_health.isHealthConnectAvailable()`.
2. Yêu cầu cấp quyền qua `_health.requestAuthorization()`. Plugin `health` mở giao diện phân quyền chính thức của Health Connect (thông qua `ActivityResultLauncher` của `FlutterFragmentActivity`) để người dùng chọn từng chỉ số: *Active calories burned*, *Heart rate*, *Sleep*, *Steps*.
3. Khi được cấp quyền, phương thức `syncNow()` truy vấn các bản ghi lịch sử cho bốn loại chỉ số: `STEPS` (số bước), `HEART_RATE` (nhịp tim), `ACTIVE_ENERGY_BURNED` (calo tiêu hao do hoạt động) và `SLEEP_SESSION` (giấc ngủ).
4. Số bước đọc về được lưu vào `StepRepository` nếu lớn hơn số bước hiện tại để hiển thị trên Dashboard; nhịp tim, giấc ngủ và calo hoạt động được lưu đệm để hiển thị trên thẻ Health Connect của tab Hồ sơ.

![Hình 3.7: Giao diện cấp quyền Health Connect cho ứng dụng](img/chup-health-connect-permission.png)

---

## 3.8. Khóa ứng dụng bằng sinh trắc học

Ứng dụng cho phép bật khóa bằng vân tay hoặc khuôn mặt để bảo vệ dữ liệu sức khỏe. Lớp `BiometricService` bọc plugin `local_auth`, gọi API `BiometricPrompt` của Android (`biometricOnly: false` cho phép dùng mã PIN/mật khẩu thiết bị thay thế); vì plugin này cần một `FragmentActivity`, `MainActivity` kế thừa `FlutterFragmentActivity` (mục 1.2.2). Widget `BiometricGate` bọc ngoài màn hình chính: khi cờ `biometric_app_lock_enabled` đang bật, nội dung bị che và hộp thoại xác thực của hệ thống xuất hiện mỗi lần mở ứng dụng.

Hộp thoại `BiometricPrompt` là cửa sổ bảo mật của hệ thống, các hãng điện thoại không cho phép chụp màn hình (ảnh chụp chỉ ra màn hình đen), nên báo cáo chỉ mô tả ngắn chức năng này và không kèm hình minh họa.

---

## 3.9. Tích hợp phần cứng: Camera, nhận diện mã vạch và nhận dạng giọng nói

Ứng dụng khai thác cụm Camera và Microphone trên thiết bị Android để hỗ trợ người dùng nhập liệu dinh dưỡng thuận tiện hơn.

### 3.9.1. Quét mã vạch thực phẩm với MobileScanner và CameraX

Để người dùng không phải gõ tay tên từng loại thực phẩm đóng gói, nhóm xây dựng thành phần `BarcodeScannerSheet` sử dụng plugin `mobile_scanner`, hoạt động dựa trên **CameraX API** và thư viện **Google ML Kit Barcode Scanning**.

Quy trình hoạt động:
1. Khi mở giao diện quét mã, ứng dụng yêu cầu cấp quyền `android.permission.CAMERA`.
2. Khởi tạo bộ điều khiển `MobileScannerController`:

```dart
_scannerController = MobileScannerController(
  detectionSpeed: DetectionSpeed.normal,
  facing: CameraFacing.back,
  torchEnabled: false,
);
```
(Nguồn: `lib/widgets/barcode_scanner_sheet.dart:54-58`)

3. CameraX cung cấp luồng khung hình xem trước hiển thị trên `SurfaceTexture` của Flutter. Bộ phân tích hình ảnh (*ImageAnalysis*) chuyển các khung hình dạng đệm nhị phân tới mô hình ML Kit trên thiết bị để phát hiện các định dạng mã vạch EAN-13, EAN-8, UPC-A, UPC-E.
4. Khi mã vạch được nhận diện trong `onDetect`, ứng dụng bật cờ `_isProcessing` để bỏ qua các khung hình tiếp theo (tránh gọi API trùng lặp), rồi gọi API `Open Food Facts` để truy vấn thông tin calo, protein, carbohydrate và chất béo. Người dùng chọn hệ số khẩu phần (0.5×–2.0×) và bữa ăn trước khi thêm vào nhật ký.

Ngoài camera trực tiếp, người dùng có thể bấm nút thư viện ở góc trên để chọn ảnh mã vạch có sẵn: ảnh được đưa vào `MobileScannerController.analyzeImage(path)`, ML Kit phân tích ảnh tĩnh và trả về mã, sau đó đi theo cùng luồng tra cứu Open Food Facts. Trên thiết bị thử nghiệm, chọn ảnh mã EAN-13 `3017620422003` cho ra đúng sản phẩm Nutella (539 kcal/100 g).

### 3.9.2. Ghi chép món ăn bằng giọng nói qua RecognitionService

Đối với các món ăn nấu tại nhà không có mã vạch, nhóm tích hợp tính năng nhập liệu bằng giọng nói qua lớp `SpeechService`, sử dụng plugin `speech_to_text`.

Dưới tầng Android, plugin liên kết với dịch vụ nhận dạng tiếng nói hệ thống `android.speech.RecognitionService`. Để hoạt động trên Android 11+ (API level 30), ứng dụng hoàn thiện hai yêu cầu:
1. Khai báo quyền ghi âm trong Manifest: `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`.
2. Khai báo dịch vụ nhận dạng giọng nói trong thẻ `<queries>`:

```xml
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```
(Nguồn: `android/app/src/main/AndroidManifest.xml:121-123`)

Nếu thiếu khai báo `<queries>`, phương thức `initialize()` sẽ trả về `false` do cơ chế hạn chế hiển thị gói của hệ điều hành. `SpeechService.initialize()` được gọi khi thẻ "AI ghi nhận món ăn" trên Dashboard khởi tạo, vì vậy hộp thoại xin quyền micro xuất hiện ngay lần đầu mở Dashboard. Khi người dùng bấm nút micro và nói, `RecognitionService` chuyển đổi âm thanh thành văn bản và trả về giao diện; nội dung này được gửi tới mô hình Gemini để phân tích thành các trường dữ liệu món ăn và định lượng calo.

---

## 3.10. Bảng tổng hợp quyền hệ thống và cơ chế cấp quyền thời gian chạy

Hệ thống bảo mật của Android phân cấp quyền theo nhiều mức độ: quyền thông thường (*Normal Permissions*), quyền nguy hiểm cần cấp khi chạy (*Dangerous / Runtime Permissions*), và các quyền chuyên biệt của dịch vụ nền (*Special Permissions*).

### 3.10.1. Bảng tổng hợp quyền Android trong ứng dụng

Bảng 3.1 tổng hợp danh mục các quyền được khai báo trong dự án Fitness Tracker, phân loại theo cấp độ bảo vệ và mục đích kỹ thuật:

Bảng 3.1: Danh mục quyền hệ thống Android trong ứng dụng Fitness Tracker

| Tên quyền (`android.permission.*`) | Phân loại quyền | API Level | Mục đích kỹ thuật trong ứng dụng |
|---|---|---|---|
| `ACTIVITY_RECOGNITION` | Nguy hiểm (Runtime) | API 29+ | Truy cập cảm biến bước chân phần cứng `TYPE_STEP_COUNTER`. |
| `POST_NOTIFICATIONS` | Nguy hiểm (Runtime) | API 33+ | Hiển thị thông báo bước chân, nhắc uống nước và đếm ngược nghỉ hiệp. |
| `RECORD_AUDIO` | Nguy hiểm (Runtime) | API 23+ | Thu âm phục vụ nhận dạng giọng nói chuyển thành món ăn. |
| `CAMERA` | Nguy hiểm (Runtime) | API 23+ | Mở camera quét mã vạch qua CameraX và ML Kit. |
| `FOREGROUND_SERVICE` | Thông thường (Normal) | API 28+ | Khởi chạy dịch vụ tiền đình chạy bền bỉ dưới nền hệ thống. |
| `FOREGROUND_SERVICE_HEALTH` | Thông thường (Normal) | API 34+ | Phân loại dịch vụ chạy nền thuộc nhóm sức khỏe theo quy chuẩn Google Play. |
| `RECEIVE_BOOT_COMPLETED` | Thông thường (Normal) | Mọi API | Nhận tín hiệu khởi động máy để tự kích hoạt lại `StepCounterService`. |
| `SCHEDULE_EXACT_ALARM` | Đặc biệt (AppOps) | API 31+ | Đặt lịch báo thức chính xác cho chu kỳ nhắc nhở uống nước. |
| `USE_EXACT_ALARM` | Thông thường (Normal) | API 33+ | Hỗ trợ thực thi báo thức chính xác trên Android 13+. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Thông thường (Normal) | API 23+ | Mở Intent xin đưa ứng dụng vào danh sách miễn trừ Doze mode. |
| `VIBRATE` | Thông thường (Normal) | Mọi API | Rung phản hồi khi hoàn tất thời gian nghỉ hiệp hoặc nhấn nút. |
| `INTERNET` | Thông thường (Normal) | Mọi API | Kết nối Firebase Cloud Firestore, Open Food Facts và Gemini API. |
| `health.READ_STEPS` | Quyền Health Connect | API 34+ | Đọc chỉ số bước chân từ nền tảng Google Health Connect. |
| `health.READ_HEART_RATE` | Quyền Health Connect | API 34+ | Đọc chỉ số nhịp tim từ nền tảng Google Health Connect. |
| `health.READ_TOTAL_CALORIES_BURNED` | Quyền Health Connect | API 34+ | Đọc tổng calo tiêu thụ từ nền tảng Google Health Connect. |
| `health.READ_ACTIVE_CALORIES_BURNED` | Quyền Health Connect | API 34+ | Đọc calo tiêu hao do hoạt động (`ACTIVE_ENERGY_BURNED`). |
| `USE_BIOMETRIC` | Thông thường (Normal) | API 28+ | Do plugin `local_auth` khai báo, gộp vào Manifest khi build. |
| `health.READ_SLEEP` | Quyền Health Connect | API 34+ | Đọc phiên giấc ngủ từ nền tảng Google Health Connect. |

### 3.10.2. Quy trình xin cấp quyền thời gian chạy và kiểm tra bằng công cụ ADB

Đối với các quyền nguy hiểm (`ACTIVITY_RECOGNITION`, `POST_NOTIFICATIONS`, `RECORD_AUDIO`, `CAMERA`), nếu ứng dụng truy cập tài nguyên phần cứng mà người dùng chưa cấp quyền tại thời điểm chạy (*Runtime*), hệ thống sẽ ném ngoại lệ `SecurityException` và dừng ứng dụng.

Thời điểm xin từng quyền trong ứng dụng (đã quan sát trên thiết bị khi cài mới):
- `POST_NOTIFICATIONS`: xin ngay khi khởi động, trong lúc `NotificationService.init()` chạy.
- `ACTIVITY_RECOGNITION`: xin khi widget đếm bước được dựng trên Dashboard; hàm `_initStepCounter()` gọi `Permission.activityRecognition.request()` và chỉ gọi `startService` xuống tầng Native khi người dùng chấp thuận. Nếu hộp thoại quyền đóng mà dịch vụ chưa chạy, `StepCounterWidget` kiểm tra lại quyền khi ứng dụng trở lại tiền cảnh để khởi chạy bù.
- `RECORD_AUDIO`: xin khi Dashboard khởi tạo dịch vụ giọng nói (mục 3.9.2).
- `CAMERA`: xin đúng lúc người dùng mở trình quét mã vạch (*Just-in-Time*).

Để kiểm tra trạng thái dịch vụ tiền đình trên thiết bị thử nghiệm (Xiaomi chạy HyperOS 3, Android 16), nhóm sử dụng công cụ ADB thực thi lệnh:

```bash
adb shell dumpsys activity services com.nhh031.fitness_tracker
```

Kết quả phản hồi xác nhận `StepCounterService` đang vận hành ở tiền cảnh với `isForeground=true`, `types=0x00000100` (giá trị của `FOREGROUND_SERVICE_TYPE_HEALTH`) và thông báo thuộc kênh `StepCounterChannel`:

![Hình 3.8: Kiểm tra trạng thái Foreground Service bằng lệnh adb dumpsys](img/chup-adb-dumpsys.png)
> CHỤP: Kết quả chạy lệnh adb shell dumpsys activity services com.nhh031.fitness_tracker / hiển thị StepCounterService với isForeground=true / chạy lệnh adb từ terminal máy tính khi kết nối điện thoại.

Các câu lệnh ADB khác được nhóm sử dụng để xác minh hoạt động của ứng dụng:
- **Kiểm tra danh sách trắng tiết kiệm pin (Doze whitelist)**:
  `adb shell dumpsys deviceidle whitelist | findstr com.nhh031.fitness_tracker`
- **Kiểm tra các quyền runtime đã cấp**:
  `adb shell dumpsys package com.nhh031.fitness_tracker | findstr granted`
- **Kiểm tra lịch nhắc uống nước đã đăng ký với AlarmManager**:
  `adb shell dumpsys alarm | findstr fitness_tracker`
- **Kiểm tra thông tin đăng ký của App Widget**:
  `adb shell dumpsys appwidget | findstr com.nhh031.fitness_tracker`
- **Kiểm tra BootReceiver**: khởi động lại thiết bị bằng `adb reboot`, sau đó chạy lại `adb shell dumpsys activity services com.nhh031.fitness_tracker`. (Lệnh giả lập `am broadcast -a android.intent.action.BOOT_COMPLETED` bị hệ thống từ chối với `SecurityException: Permission Denial` trên Android 16 không root, vì đây là broadcast được bảo vệ.)

Các kết quả thực nghiệm trên cho thấy các kỹ thuật lập trình Android nâng cao được triển khai trong ứng dụng vận hành ổn định và tuân thủ các quy chuẩn kiến trúc của hệ điều hành Android.
