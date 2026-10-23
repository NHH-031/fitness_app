# CHƯƠNG 1. GIỚI THIỆU CHUNG VÀ CƠ SỞ LÝ THUYẾT

## 1.1. Bài toán theo dõi sức khỏe và luyện tập trên thiết bị di động

Sự phổ biến của điện thoại thông minh (*smartphones*) đã thúc đẩy xu hướng tự theo dõi sức khỏe cá nhân (*mobile health* hay *mHealth*). Người dùng ngày nay có nhu cầu ghi nhận liên tục các chỉ số thể chất hàng ngày như số bước chân, năng lượng tiêu hao, lượng nước uống, dinh dưỡng và nhật ký rèn luyện. Việc xây dựng ứng dụng hỗ trợ sức khỏe đòi hỏi kết hợp giữa thu thập dữ liệu phần cứng liên tục và một giao diện trực quan, dễ tiếp cận.

Tuy nhiên, bài toán theo dõi vận động liên tục trên thiết bị di động đối mặt với bốn thách thức kỹ thuật chính:

1. *Mức tiêu thụ năng lượng của cảm biến*: Để phản ánh chính xác khối lượng vận động, ứng dụng cần lắng nghe cảm biến chuyển động liên tục (24/7). Nếu ứng dụng liên tục đánh thức bộ vi xử lý trung tâm (*CPU*) để xử lý từng tín hiệu cảm biến riêng lẻ, thiết bị sẽ nhanh chóng cạn kiệt pin, ảnh hưởng xấu đến thời lượng sử dụng của máy.
2. *Quản lý năng lượng của hệ điều hành*: Nhằm tiết kiệm pin, các phiên bản Android hiện đại áp dụng chính sách quản lý tiến trình ngầm qua chế độ ngủ sâu (*Doze Mode*) và chế độ chờ (*App Standby*). Khi màn hình tắt hoặc khi người dùng không tương tác, hệ thống sẽ tạm dừng hoặc dừng các dịch vụ chạy ngầm (*background services*), gây gián đoạn việc ghi nhận bước chân.
3. *Độ tin cậy và tính toàn vẹn của dữ liệu*: Cảm biến bước chân phần cứng tích lũy số bước từ lúc bật máy và tự động đặt lại về 0 khi khởi động lại. Do đó, ứng dụng cần thuật toán tính mốc cơ sở (*baseline*) và độ lệch sau khởi động (*reboot offset*) nhằm đảm bảo số bước chân trong ngày không bị nhảy lùi hoặc mất mát dữ liệu khi thiết bị tắt nguồn hoặc khởi động lại.
4. *Cân bằng hiệu năng giao diện và xử lý nền tảng*: Ứng dụng đòi hỏi giao diện trực quan, hiển thị động học chuyển động và biểu đồ phân tích, đồng thời phải bảo đảm các tiến trình chạy nền vận hành ổn định, sử dụng hợp lý bộ nhớ RAM và không gây xung đột dữ liệu giữa tầng giao diện và tầng dịch vụ hệ thống.

---

## 1.2. Nền tảng hệ điều hành Android

### 1.2.1. Kiến trúc Android Runtime và vòng đời ứng dụng di động

Hệ điều hành Android cung cấp môi trường thực thi và bảo mật cho ứng dụng qua Android Runtime (*ART*), thay thế máy ảo Dalvik từ Android 5.0 (API level 21).

Khác với cơ chế biên dịch JIT của Dalvik vốn tiêu tốn CPU khi khởi chạy, ART áp dụng biên dịch trước (*Ahead-of-Time* - AOT) khi cài đặt, chuyển đổi mã *DEX bytecode* thành mã máy nhị phân bản địa (*native machine code*). Từ Android 7.0 (API level 24), ART kết hợp biên dịch JIT và AOT cùng bộ định hình hồ sơ thực thi (*Profile-guided compilation*), tối ưu hóa các đoạn mã hay dùng (*hot code*) khi máy nhàn rỗi, giúp rút ngắn thời gian khởi động và tiết kiệm tài nguyên. Cơ chế thu gom rác (*Garbage Collection*) trong ART cũng được cải tiến, giảm thời gian dừng tiến trình (*pause time*) và duy trì tốc độ kết xuất khung hình ổn định.

Mỗi ứng dụng Android chạy trong một không gian tiến trình riêng với định danh người dùng độc lập (*User ID* - UID), tạo cơ chế hộp cát bảo mật (*application sandboxing*). Hệ thống quản lý vòng đời tiến trình theo 4 mức ưu tiên:
- *Tiến trình tiền cảnh (Foreground Process)*: Đang tương tác với người dùng (như `Activity` ở trạng thái `onResume()` hoặc `Service` gắn với thông báo tiền cảnh qua `startForeground()`). Tiến trình này có độ ưu tiên cao nhất.
- *Tiến trình nhìn thấy (Visible Process)*: Thành phần vẫn hiển thị nhưng không trực tiếp tương tác (như `Activity` bị che khuất một phần bởi hộp thoại).
- *Tiến trình dịch vụ (Service Process)*: Chạy dịch vụ nền thông thường không có giao diện hiển thị.
- *Tiến trình lưu đệm (Cached Process)*: Không còn hiển thị và không có tác vụ chạy, được ưu tiên giải phóng bởi bộ dọn dẹp bộ nhớ (*Low Memory Killer Daemon* - lmkd) khi thiếu RAM.

Vòng đời `Activity` gồm: `onCreate()`, `onStart()`, `onResume()`, `onPause()`, `onStop()`, và `onDestroy()`. Do hệ điều hành có thể hủy tiến trình khi ứng dụng rơi vào hậu cảnh, tác vụ đếm bước chân liên tục bắt buộc phải ủy quyền cho dịch vụ chuyên biệt của hệ thống Android.

### 1.2.2. Các thành phần ứng dụng Android cơ bản: Activity, Service, BroadcastReceiver, App Widget, Notification

Kiến trúc ứng dụng Android gồm các khối thành phần cốt lõi liên kết qua thông điệp `Intent`:

1. *Activity*: Đại diện cho giao diện người dùng đơn lẻ. Lớp `MainActivity` kế thừa `FlutterFragmentActivity`, đóng vai trò là cửa sổ đồ họa chính khởi tạo Flutter Engine, tiếp nhận sự kiện chạm và làm điểm kết nối các kênh giao tiếp nền tảng. Ứng dụng dùng `FlutterFragmentActivity` (thay vì `FlutterActivity`) vì hai plugin hệ thống cần một `FragmentActivity`: plugin `health` đăng ký `ActivityResultLauncher` để mở hộp thoại cấp quyền của Health Connect, còn `local_auth` cần `FragmentActivity` để hiển thị `BiometricPrompt`.
2. *Service và Foreground Service*: Thực thi tác vụ kéo dài không cần giao diện. Kể từ Android 8.0 (API level 26), hệ điều hành giới hạn thực thi nền (*Background Execution Limits*). Để theo dõi vận động liên tục, ứng dụng sử dụng dịch vụ tiền cảnh (*Foreground Service*). Dịch vụ tiền cảnh thuộc nhóm tiến trình tiền cảnh, không bị lmkd tiêu diệt khi thiếu RAM, và bắt buộc gắn với một thông báo liên tục (*Ongoing Notification*) trên khay hệ thống. Khi khởi tạo, ứng dụng gọi `startForegroundService()`; dịch vụ gọi `startForeground()` ngay trong `onCreate()`, còn `onStartCommand()` trả về `START_STICKY` để hệ thống tự khởi động lại dịch vụ nếu tiến trình bị dừng đột ngột.

```xml
<service
    android:name=".StepCounterService"
    android:foregroundServiceType="health"
    android:exported="false" />
```
(Nguồn: android/app/src/main/AndroidManifest.xml:69-72)

3. *BroadcastReceiver*: Lắng nghe và phản hồi thông điệp truyền phát (*Broadcast Intent*). Đăng ký tĩnh khai báo trong `AndroidManifest.xml` (như `BootReceiver` lắng nghe `BOOT_COMPLETED` để tự phục hồi dịch vụ đếm bước). Đăng ký động thực hiện qua mã lệnh (như bộ thu trong `MainActivity`), từ Android 13 (API level 33) yêu cầu chỉ định rõ cờ an toàn `Context.RECEIVER_NOT_EXPORTED` nhằm ngăn chặn các thông điệp giả mạo từ ứng dụng bên ngoài.
4. *App Widget*: Tiện ích hiển thị trên màn hình chính (*Home Screen*), cho phép người dùng xem nhanh thông tin mà không cần mở ứng dụng. App Widget chạy trên tiến trình Launcher thông qua `AppWidgetProvider` kết hợp với `RemoteViews`, cập nhật dữ liệu định kỳ qua `AppWidgetManager`.
5. *Notification và Notification Channel*: Cung cấp cảnh báo và tiến độ ra ngoài màn hình chính. Từ Android 8.0, mọi thông báo bắt buộc gắn vào một kênh thông báo (*Notification Channel*) có định danh và mức độ ưu tiên xác định (*Importance Level*), tương tác với người dùng qua `PendingIntent` với cờ an toàn `FLAG_IMMUTABLE`.

### 1.2.3. Hệ thống cảm biến trong Android (SensorManager, cơ chế cảm biến đếm bước chân phần cứng TYPE_STEP_COUNTER, batching)

Hệ thống cảm biến Android được tổ chức theo mô hình phân tầng từ phần cứng cảm biến vi cơ điện tử (*MEMS*), qua tầng trừu tượng phần cứng (*Sensor HAL*), dịch vụ hệ thống `SensorService`, tới tầng ứng dụng qua lớp `SensorManager`.

![Hình 1.1: Kiến trúc phân tầng cảm biến và cơ chế Sensor Batching trong Android](img/so-do-kien-truc-sensor-android.png)

Để truy cập cảm biến, ứng dụng sử dụng `SensorManager` qua `getSystemService(Context.SENSOR_SERVICE)` và triển khai `SensorEventListener` để nhận dữ liệu tại hàm phản hồi `onSensorChanged(SensorEvent)`.

Đối với bài toán theo dõi bước chân, Android cung cấp các cơ chế cảm biến:
- *Cảm biến gia tốc (TYPE_ACCELEROMETER)*: Đo gia tốc 3 trục. Việc nhận diện bước chân đòi hỏi thuật toán xử lý tín hiệu số phức tạp, tiêu tốn CPU và có sai số lớn khi người dùng di chuyển bằng phương tiện giao thông.
- *Cảm biến phát hiện bước chân (TYPE_STEP_DETECTOR)*: Kích hoạt sự kiện mỗi khi phát hiện một bước chân riêng lẻ, độ trễ thấp nhưng đòi hỏi hệ thống xử lý ngắt liên tục.
- *Cảm biến đếm bước chân phần cứng (TYPE_STEP_COUNTER)*: Hỗ trợ từ Android 4.4 (API level 19). Bộ vi điều khiển cảm biến độc lập (*Sensor Hub*) tự động đếm và duy trì tổng số bước chân tích lũy kể từ khi thiết bị khởi động lại. Dữ liệu có độ ổn định cao và tiêu thụ ít năng lượng do việc nhận diện thực hiện trực tiếp ở cấp độ phần cứng.

Nhằm tối ưu hóa năng lượng tiêu thụ, Android cung cấp cơ chế gộp mẫu cảm biến (*Sensor Batching*). Khi đăng ký lắng nghe cảm biến bằng phương thức `registerListener()`, ứng dụng truyền tham số độ trễ báo cáo tối đa `maxReportLatency`:

```kotlin
sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
stepSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
stepSensor?.let {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
        // Gộp mẫu cảm biến với độ trễ 10 giây để tiết kiệm pin
        sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL, 10000000)
    } else {
        sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
    }
}
```
(Nguồn: android/app/src/main/kotlin/com/example/fitness_tracker/StepCounterService.kt:39-48)

Với tham số `maxReportLatency = 10_000_000` micro giây (10 giây), chip cảm biến tự động lưu trữ các sự kiện bước chân vào bộ nhớ đệm phần cứng (*Hardware FIFO Queue*) mà không phát tín hiệu ngắt đánh thức CPU. Chỉ khi hết chu kỳ 10 giây hoặc khi bộ đệm FIFO đầy, phần cứng mới phát một tín hiệu ngắt để chuyển dữ liệu về cho hệ điều hành xử lý. Cơ chế này giúp CPU duy trì trạng thái ngủ sâu (*Deep Sleep*), cho phép ứng dụng theo dõi vận động liên tục mà không làm hao pin nhanh.

### 1.2.4. Mô hình phân quyền Android (tiến hóa quyền từ Android 8.0 đến Android 14/15/16)

Mô hình phân quyền Android đã tiến hóa nhằm nâng cao tính minh bạch và bảo vệ quyền riêng tư người dùng:

1. *Quyền thời điểm thực thi (Runtime Permissions)*: Từ Android 6.0 (API level 23), các quyền thuộc nhóm nguy hiểm (*Dangerous Permissions*) như máy ảnh, vị trí, ghi âm bắt buộc người dùng cấp phép tường minh qua hộp thoại hệ thống ngay tại thời điểm sử dụng tính năng.
2. *Quyền nhận diện vận động (ACTIVITY_RECOGNITION)*: Từ Android 10 (API level 29), Google tách quyền truy cập cảm biến bước chân ra khỏi các cảm biến thông thường và đặt dưới quyền thời điểm thực thi `android.permission.ACTIVITY_RECOGNITION`. Nếu không được cấp quyền, ứng dụng không nhận được dữ liệu từ `Sensor.TYPE_STEP_COUNTER`.
3. *Quyền phát thông báo (POST_NOTIFICATIONS)*: Từ Android 13 (API level 33), quyền gửi thông báo `android.permission.POST_NOTIFICATIONS` trở thành quyền thời điểm thực thi, yêu cầu ứng dụng giải thích lý do cần thông báo trước khi đề nghị cấp quyền.
4. *Phân loại dịch vụ tiền cảnh (Foreground Service Types)*: Từ Android 14 (API level 34) đến Android 16, dịch vụ tiền cảnh bắt buộc phải khai báo thuộc tính `foregroundServiceType` trong `AndroidManifest.xml` cùng quyền tương ứng. Với ứng dụng thể thao và sức khỏe, bắt buộc khai báo `foregroundServiceType="health"` đi kèm quyền `android.permission.FOREGROUND_SERVICE_HEALTH`. Nếu gọi `startForeground()` mà không khai báo đúng loại dịch vụ, hệ thống Android 14+ sẽ ném ngoại lệ `SecurityException` và dừng tiến trình.
5. *Quyền lập lịch chính xác và hiển thị gói ứng dụng*: Android 12 (API level 31) bổ sung quyền `android.permission.SCHEDULE_EXACT_ALARM` để kiểm soát báo thức chính xác từng giây. Android 11 (API level 30) thắt chặt khả năng nhìn thấy ứng dụng khác (*Package Visibility*), yêu cầu khai báo khối `<queries>` tại `AndroidManifest.xml` cho các gói như Google Health Connect (`com.google.android.apps.healthdata`) và dịch vụ nhận dạng giọng nói (`RecognitionService`).

---

## 1.3. Framework Flutter và cơ chế Platform Channel

Flutter là bộ công cụ phát triển giao diện người dùng (*UI SDK*) mã nguồn mở do Google phát triển. Trong đề tài, nhóm dùng Flutter để xây dựng giao diện cho ứng dụng Android; mã nguồn Dart được biên dịch ra mã máy khi đóng gói APK.

Khác với các giải pháp lai (*Hybrid*) phụ thuộc vào WebView hoặc cầu nối Javascript ánh xạ widget, Flutter sở hữu bộ máy kết xuất đồ họa độc lập (Flutter Engine viết bằng C++). Engine này sử dụng thư viện Impeller hoặc Skia để trực tiếp vẽ từng điểm ảnh (*pixel-level rendering*) lên bề mặt đồ họa của Android (`SurfaceView`). Nhờ đó, Flutter duy trì tốc độ kết xuất 60 đến 120 khung hình mỗi giây và bảo đảm tính nhất quán giao diện trên nhiều thiết bị.

Do máy ảo Dart vận hành trong các luồng cách ly (*Isolates*) và không thể truy cập trực tiếp vào các hàm API của Android, Flutter sử dụng cơ chế cầu nối nền tảng (*Platform Channel*) để giao tiếp giữa tầng Dart và tầng native (Kotlin/Java):

![Hình 1.2: Cơ chế giao tiếp qua Platform Channel giữa Flutter và Android Native](img/so-do-platform-channel.png)

Cơ chế Platform Channel hoạt động dựa trên việc gửi nhận thông điệp bất đồng bộ qua đối tượng `BinaryMessenger` của Flutter Engine. Dữ liệu trao đổi giữa Dart và Android được tuần tự hóa và giải mã thành các gói tin nhị phân bằng bộ mã hóa tiêu chuẩn `StandardMethodCodec` (hỗ trợ boolean, số nguyên, số thực, chuỗi ký tự, danh sách và bảng ánh xạ khóa - giá trị).

Hệ thống Platform Channel trong dự án bao gồm hai cơ chế kênh chính:

1. *MethodChannel (Kênh gọi hàm hai chiều có phản hồi)*: Hoạt động theo mô hình gọi thủ tục từ xa (*Remote Procedure Call* - RPC), phù hợp cho tác vụ dạng Yêu cầu - Phản hồi (*Request - Response*). Tầng Dart gửi thông điệp kèm tên phương thức và đối số qua `invokeMethod()`, trả về một đối tượng `Future`. Tầng Android cài đặt `MethodChannel.MethodCallHandler`, đón nhận thông điệp trong `onMethodCall()` và trả về kết quả qua `result.success()` hoặc báo lỗi qua `result.error()`.

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
    when (call.method) {
        "startService" -> {
            val serviceIntent = Intent(this, StepCounterService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            result.success(null)
        }
        // ...
    }
}
```
(Nguồn: android/app/src/main/kotlin/com/example/fitness_tracker/MainActivity.kt:35-45)

Trong dự án, `MethodChannel` (`'com.example.fitness_tracker/service'`) được dùng để điều khiển khởi chạy dịch vụ nền `StepCounterService`, kiểm tra miễn trừ tiết kiệm pin (`isIgnoringBatteryOptimizations`), yêu cầu mở hộp thoại xin bỏ qua Doze mode (`requestIgnoreBatteryOptimizations`), và yêu cầu cập nhật App Widget (`updateWidget`).

2. *EventChannel (Kênh phát luồng dữ liệu liên tục một chiều)*: Hoạt động theo mô hình Xuất bản - Đăng ký (*Publish - Subscribe*), phục vụ truyền các luồng dữ liệu sự kiện phát sinh liên tục theo thời gian. Tầng Dart lắng nghe qua `receiveBroadcastStream()`, trả về một `Stream`. Tầng native Kotlin cài đặt giao diện `EventChannel.StreamHandler` gồm hai phương thức: `onListen(arguments, events)` (nhận đối tượng `EventSink` để phát dữ liệu) và `onCancel(arguments)` (giải phóng tài nguyên).

Trong dự án, kênh `EventChannel` (`'com.example.fitness_tracker/steps'`) kết nối với một bộ thu `BroadcastReceiver` động bên trong `MainActivity`. Khi `StepCounterService` ghi nhận bước chân mới từ phần cứng, nó phát một Intent nội bộ tới `MainActivity`, từ đó chuyển tiếp dữ liệu vào `eventSink.success(steps)` để giao diện Flutter cập nhật chỉ số bước chân trên vòng tròn tiến độ.

Bên cạnh Platform Channel, ứng dụng còn chia sẻ dữ liệu ngầm thông qua tệp cấu hình `"FlutterSharedPreferences"` (`Context.MODE_PRIVATE`). Do package `shared_preferences` lưu trữ dữ liệu vào tệp XML này với tiền tố `flutter.`, các thành phần native như `StepCounterService` và `FitnessAppWidgetProvider` có thể trực tiếp đọc và ghi các khóa như `flutter.today_steps` hay `flutter.water_cups_today` mà không phụ thuộc vào trạng thái chạy của Flutter Engine.

---

## 1.4. Tổng quan công nghệ và các thư viện sử dụng

Để xây dựng ứng dụng theo dõi thể chất, dự án kết hợp các công nghệ nền tảng di động, hệ thống cơ sở dữ liệu quan hệ cục bộ, dịch vụ đám mây và các mô hình trí tuệ nhân tạo. Danh mục công nghệ và các thư viện chính được tổng hợp chi tiết trong Bảng 1.1:

Bảng 1.1: Danh mục công nghệ và thư viện chính trong dự án

| Nhóm công nghệ | Tên công nghệ / Thư viện | Phiên bản | Vai trò và chức năng chính |
|---|---|---|---|
| **Nền tảng** | Flutter SDK | 3.47.6 | Framework chính phát triển giao diện ứng dụng Android |
| | Dart SDK | 3.13.5 | Ngôn ngữ lập trình logic ứng dụng và giao diện |
| | Android SDK & Kotlin | Kotlin 2.2.20 | Tầng xử lý native, Foreground Service, cảm biến |
| **Lưu trữ** | `sqflite` | ^2.4.2+1 | CSDL SQLite cục bộ lưu 7 bảng quan hệ |
| | `shared_preferences` | ^2.5.5 | Lưu cấu hình và chia sẻ dữ liệu đệm với native |
| **Đám mây** | `firebase_auth` & `cloud_firestore` | ^6.7 / ^6.10 | Xác thực người dùng và đồng bộ NoSQL 2 chiều |
| | `google_sign_in` | ^7.2.0 | Đăng nhập một chạm qua Google OAuth |
| **Hệ thống** | `local_auth` | ^3.0.2 | Xác thực sinh trắc học vân tay qua BiometricPrompt |
| | `health` | ^13.3.2 | Xin quyền và đọc dữ liệu từ Google Health Connect |
| | `flutter_local_notifications` | ^22.0.0-dev.3 | Thông báo nhắc nước, đồng hồ nghỉ hiệp và Notification Channel |
| | `permission_handler` | ^11.3.1 | Quản lý yêu cầu cấp quyền thực thi runtime |
| **AI & Dịch vụ** | `google_generative_ai` | ^0.4.7 | SDK gọi mô hình Gemini `gemini-2.5-flash` |
| | `http` (Open Food Facts) | ^1.6.0 | REST API tra cứu cơ sở dữ liệu dinh dưỡng sản phẩm |
| | `mobile_scanner` | ^7.4.2 | Quét mã vạch thực phẩm qua CameraX và ML Kit |
| | `speech_to_text` | ^7.4.0 | Nhận dạng giọng nói chuyển thành văn bản ghi món ăn |
| **Giao diện** | `fl_chart` | ^1.2.0 | Kết xuất biểu đồ cột calo và biểu đồ tròn macro |
| | `figma_squircle` | ^0.6.3 | Bo góc squircle mịn cho thẻ giao diện Dark Theme |

Hệ sinh thái thư viện trên hỗ trợ mô hình *Local-First*: SQLite (`sqflite`) và SharedPreferences lưu dữ liệu tại chỗ, đảm bảo ứng dụng vận hành bình thường khi mất kết nối mạng. Tầng AI gọi Google Gemini (`gemini-2.5-flash`), kết hợp bộ đệm 23 món ăn tính sẵn và cho phép nhập tay khi không gọi được AI.

---

## 1.5. Môi trường phát triển và thử nghiệm

Toàn bộ quá trình lập trình, phân tích mã nguồn, kiểm thử tự động và đóng gói ứng dụng được nhóm thực hiện trên môi trường phát triển đồng nhất với các thông số kỹ thuật được xác minh thực tế:

1. *Môi trường máy trạm phát triển*:
- Hệ điều hành: Microsoft Windows 11 phiên bản 24H2 (64-bit).
- Bộ công cụ phát triển: Flutter SDK 3.47.6 (kênh stable) và Dart SDK 3.13.5.
- Môi trường thực thi Java: Eclipse Temurin OpenJDK 21 (nhóm lựa chọn JDK 21 do Gradle 8.14 chưa tương thích với JDK 25).

2. *Cấu hình hệ thống biên dịch Android*:
- Công cụ điều phối và plugin: Gradle 8.14, Android Gradle Plugin (AGP) 8.11.1, Kotlin 2.2.20.
- Android SDK: build-tools 36.0.0, `compileSdk` và `targetSdk` tuân theo Flutter SDK, `minSdk = 26` (Android 8.0 Oreo), hỗ trợ Java desugaring với `desugar_jdk_libs:2.1.4`.

3. *Kết quả kiểm tra chất lượng mã nguồn*:
- Phân tích tĩnh (*Static Analysis*): Lệnh `flutter analyze` đạt 0 lỗi và 0 cảnh báo (*No issues found*), tuân thủ bộ luật `flutter_lints`.
- Kiểm thử tự động (*Automated Testing*): Lệnh `flutter test` đạt 123/123 test case vượt qua (100% pass) trên 17 tệp kiểm thử trong thư mục `test/`.

4. *Bản đóng gói và thiết bị thử nghiệm thực tế*:
- Bản dựng đóng gói: Tệp APK debug kích thước ~229 MB, biên dịch qua lệnh:
  ```bash
  flutter build apk --debug --dart-define-from-file=.env
  ```
- Thiết bị thử nghiệm vật lý: Điện thoại Xiaomi, model `25053RT47C`, chạy Xiaomi HyperOS 3.0 trên nền tảng Android 16 (API level 36), tích hợp Google Play Services.
- Cài đặt và gỡ lỗi: Cài đặt qua cáp USB (*USB debugging*) hoặc gỡ lỗi không dây (*Wireless Debugging*) bằng lệnh `adb install`. Ứng dụng khởi động ổn định, vùng nhật ký sự cố `adb logcat -b crash` không ghi nhận `FATAL EXCEPTION` nào của ứng dụng.
- Lưu ý triển khai trên HyperOS: Do chính sách tiết kiệm pin nghiêm ngặt của HyperOS, người dùng cần bật "Tự khởi chạy" (*Autostart*) và đặt pin "Không hạn chế" (*No restrictions*) để dịch vụ tiền cảnh đếm bước chân vận hành ổn định lâu dài.
