# CHƯƠNG 2. PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

## 2.1. Khảo sát và phân tích yêu cầu hệ thống

Trong bối cảnh thiết bị di động ngày càng phổ biến, nhu cầu theo dõi sức khỏe và quản lý vận động của người dùng gia tăng nhanh chóng. Tuy nhiên, nhiều ứng dụng hiện nay phụ thuộc liên tục vào kết nối Internet, gây gián đoạn trải nghiệm tại các môi trường sóng yếu và làm gia tăng mức tiêu hao pin. Hệ thống Fitness Tracker được nhóm xây dựng theo mô hình ưu tiên cục bộ (*Local-First*): dữ liệu vận động, dinh dưỡng và thể trạng được xử lý và lưu giữ trực tiếp trên thiết bị, sau đó đồng bộ dự phòng lên đám mây khi có kết nối mạng phù hợp.

### 2.1.1. Yêu cầu chức năng

Hệ thống cung cấp bốn nhóm chức năng cốt lõi phục vụ rèn luyện thể chất:
- *Theo dõi vận động và bước chân*: Thu thập bước chân qua cảm biến phần cứng `TYPE_STEP_COUNTER` bằng dịch vụ tiền cảnh (*Foreground Service*), lọc nhiễu dao động ở tầng Dart (tối đa 5 bước/giây khi ứng dụng đang mở), tính quãng đường và calo tiêu hao, tự động đặt lại mốc khi nhận dữ liệu cảm biến đầu tiên của ngày mới và cập nhật tiện ích màn hình chính (*App Widget*).
- *Quản lý chế độ tập luyện*: Cung cấp danh mục bài tập gym và thể trọng, mô phỏng động tác trên mô hình cấu trúc cơ 2D vẽ bằng Canvas giúp kiểm tra tư thế, điều phối phiên tập với đồng hồ bấm giờ, lưu hiệp/lần/tạ và đếm ngược thời gian nghỉ.
- *Nhật ký dinh dưỡng và trợ lý AI*: Ghi nhận khẩu phần ăn, tính năng lượng và ba chất đa lượng (*Protein / Carbohydrate / Fat*), quét mã vạch qua Open Food Facts, theo dõi nước uống và hỏi đáp với trợ lý Gemini AI (`gemini-2.5-flash`).
- *Hồ sơ cá nhân và bảo mật sinh trắc học*: Tính chỉ số BMI, BMR và TDEE; lưu số đo nhân trắc học, ảnh tiến trình, bảo mật qua vân tay (*BiometricPrompt*) và hỗ trợ chuyển đổi giữa chế độ khách (*Guest Mode*) và tài khoản Google.

Bảng 2.1: Danh mục yêu cầu chức năng của hệ thống

| Mã YC | Tên chức năng | Mô tả tóm tắt | Tác nhân |
|---|---|---|---|
| F-01 | Đếm bước chân nền | Đọc `TYPE_STEP_COUNTER`, lọc nhiễu và tính calo | Cảm biến nền |
| F-02 | Đồng bộ App Widget | Hiển thị bước chân và nước uống trên màn hình chính | Cảm biến nền |
| F-03 | Quản lý bài tập | Tra cứu, lọc bài tập theo nhóm cơ và dụng cụ | Người dùng |
| F-04 | Mô hình cấu trúc cơ 2D | Vẽ vector 18 khớp xương và bản đồ nhóm cơ | Người dùng |
| F-05 | Thực hiện phiên tập | Bấm giờ phiên tập, lưu set/rep/tạ và đếm giờ nghỉ | Người dùng |
| F-06 | Nhật ký dinh dưỡng | Ghi nhận món ăn, tính calo và tỷ lệ đa lượng | Người dùng |
| F-07 | Quét mã vạch thực phẩm | Tra cứu thành phần qua Open Food Facts API | Người dùng |
| F-08 | Theo dõi nước uống | Ghi nhận số cốc nước, thể tích và sóng nước | Người dùng |
| F-09 | Trợ lý AI tư vấn | Hỏi đáp dinh dưỡng, nhận diện món ăn và tạo bài tập qua Gemini AI | Người dùng, Gemini |
| F-10 | Tính trao đổi chất | Tính BMI, BMR (Mifflin-St Jeor), TDEE và calo | Người dùng |
| F-11 | Khóa vân tay bảo mật | Kích hoạt `BiometricPrompt` khi mở ứng dụng | Người dùng |
| F-12 | Đồng bộ đám mây | Hợp nhất dữ liệu với Cloud Firestore khi có mạng | Người dùng, Firestore |

### 2.1.2. Yêu cầu phi chức năng

Hệ thống đáp ứng các tiêu chuẩn kỹ thuật nghiêm ngặt nhằm bảo đảm hiệu năng và tính ổn định:
- *Hoạt động ngoại tuyến*: Mọi tính năng cốt lõi hoạt động bình thường trên SQLite và SharedPreferences khi không có mạng.
- *Tiết kiệm năng lượng*: Gom cụm cảm biến (*sensor batching* chu kỳ 10 giây) và trì hoãn ghi đĩa (*debounced I/O*: chỉ ghi khi lệch $\ge 3$ bước hoặc sau $\ge 2$ giây).
- *Độ tin cậy*: Thuật toán bù trừ độ lệch khởi động lại (*reboot offset*) kết hợp `BootReceiver` tự chạy lại dịch vụ sau khi máy khởi động lại.
- *Hiệu năng giao diện*: Sử dụng Scoped `ValueNotifier` kết hợp bộ đệm RAM `Map<String, List<T>>` giúp cập nhật giao diện mượt mà.
- *Bảo mật và đa ngôn ngữ*: Dữ liệu thể trạng được bảo vệ bằng khóa sinh trắc học `BiometricPrompt`, giao diện hỗ trợ song ngữ qua tệp từ điển JSON của `LocaleService`.

Bảng 2.2: Danh mục yêu cầu phi chức năng của hệ thống

| Nhóm yêu cầu | Tiêu chí kỹ thuật | Giải pháp triển khai trong ứng dụng |
|---|---|---|
| Ngoại tuyến | Hoạt động bình thường khi mất mạng | CSDL SQLite nội bộ (`sqflite`) và SharedPreferences |
| Tiết kiệm pin | Giảm tần suất đánh thức CPU | Sensor batching (10s), Debounced I/O ($\ge 3$ bước / $\ge 2$s) |
| Độ tin cậy | Khôi phục số bước khi khởi động lại | Reboot-offset, `BootReceiver` tự chạy lại dịch vụ |
| Hiệu năng | Tránh giật khung hình khi đổi dữ liệu | Scoped `ValueNotifier`, bộ đệm RAM `Map<String, List<T>>` |
| Bảo mật | Ngăn chặn xem lén dữ liệu sức khỏe | Khóa vân tay `BiometricPrompt` (`local_auth`) |
| Đa ngôn ngữ | Đổi ngôn ngữ hiển thị trong ứng dụng | Tệp từ điển JSON (`vi.json`, `en.json`) qua `LocaleService` |

---

## 2.2. Sơ đồ ca sử dụng (Use Case) tổng thể

Hệ thống mô hình hóa tương tác qua bốn tác nhân (*Actors*): Người dùng trực tiếp thao tác trên giao diện; Cảm biến nền Android cung cấp bước chân qua `StepCounterService` và `BootReceiver`; Trợ lý Gemini AI xử lý tư vấn ngôn ngữ tự nhiên; và Dịch vụ đám mây Firestore lưu trữ sao lưu hai chiều.

![Hình 2.1: Sơ đồ Use Case tổng thể của hệ thống](img/so-do-use-case.png)

Hệ thống ca sử dụng trên Hình 2.1 gồm bốn phân hệ chính:
- *Theo dõi vận động*: "Đếm bước chân nền" do Cảm biến nền kích hoạt tự động, kích hoạt tiếp "Cập nhật widget màn hình chính" để hiển thị số liệu trên màn hình chính (*Home Screen*). Người dùng tương tác qua "Xem thống kê vận động ngày và tuần".
- *Quản lý tập luyện*: Người dùng thực hiện "Tra cứu danh mục bài tập", "Xem mô phỏng trên mô hình cấu trúc cơ", "Thực hiện phiên tập và đếm giờ nghỉ", và lưu kết quả qua "Ghi nhận nhật ký bài tập".
- *Dinh dưỡng & Trợ lý AI*: Gồm "Ghi nhận khẩu phần dinh dưỡng" (kết hợp "Quét mã vạch thực phẩm OpenFoodFacts"), "Theo dõi lượng nước uống" và "Tư vấn dinh dưỡng với Gemini AI".
- *Hồ sơ & Bảo mật*: Người dùng thực hiện "Cập nhật chỉ số nhân trắc học", "Bật/tắt khóa vân tay", "Chuyển đổi ngôn ngữ", "Đăng nhập Google / Chế độ khách" và "Đồng bộ dữ liệu hai chiều" với Cloud Firestore.

---

## 2.3. Kiến trúc tổng thể hệ thống

Hệ thống áp dụng kiến trúc phân tầng *Local-First*, lấy thiết bị di động làm nguồn dữ liệu gốc đáng tin cậy. Kiến trúc gồm sáu tầng chức năng với trách nhiệm rành mạch:

![Hình 2.2: Kiến trúc tổng thể hệ thống phân tầng Local-First](img/kien-truc-tong-the.png)

Chi tiết sáu tầng kiến trúc:
1. **Lớp Presentation (Giao diện Flutter)**: Điều phối bốn màn hình chính (`DashboardScreen`, `WorkoutScreen`, `FoodScreen`, `ProfileScreen`) qua `IndexedStack` để bảo toàn trạng thái cuộn và dữ liệu khi đổi tab. Tích hợp thanh điều hướng nổi kính mờ (*BackdropFilter* blur 24px) trên nền Scaffold mở rộng đáy (`extendBody: true`). Lớp này vẽ động học 18 khớp xương bằng `CustomPainter`, hiển thị biểu đồ qua `fl_chart`, sóng nước `HydrationWaveWidget`, và được bảo vệ bởi `AuthGate` cùng `BiometricGate`.
2. **Lớp State Management (Quản lý trạng thái Scoped Notifier)**: Sử dụng các `ValueNotifier<int>` độc lập trong `StorageService` (`stepUpdateNotifier`, `waterUpdateNotifier`, `foodUpdateNotifier`, `workoutUpdateNotifier`, `profileUpdateNotifier`, `chatUpdateNotifier`, `dataUpdateNotifier`). Khi dữ liệu thay đổi, notifier tăng giá trị, kích hoạt vẽ lại cục bộ chỉ trên những widget đang lắng nghe, tránh dựng lại toàn bộ cây giao diện.
3. **Lớp Data Services & Repositories (Nghiệp vụ và Kho dữ liệu)**: `StorageService` đóng vai trò Facade trung tâm. Các Repository theo miền nghiệp vụ (`StepRepository`, `WaterRepository`, `WorkoutRepository`, `NutritionRepository`, `ChatRepository`, `BodyMeasurementRepository`, `AuthRepository`) quản lý bộ nhớ đệm RAM (`Map<String, List<T>>` theo ngày) và xử lý tính toán (calo, lọc rung nhiễu bước chân).
4. **Lớp Local Storage (Lưu trữ cục bộ Local-First)**: Dữ liệu được lưu trên thiết bị theo hai cơ chế. *SQLite* (`sqflite`) quản lý CSDL `fitness_tracker.db` với 7 bảng và chỉ mục B-tree (tự chuyển sang SQLite trên bộ nhớ RAM `sqflite_common_ffi` khi chạy test CI); nhật ký món ăn, nhật ký bài tập, số đo cơ thể, món ăn ưa thích và ảnh tiến trình được ghi vào SQLite. *SharedPreferences* lưu hồ sơ người dùng (chuỗi JSON), cấu hình, cờ sinh trắc học, dữ liệu bước chân dùng chung với native Android, cùng lịch sử nước uống và lịch sử chat AI dạng danh sách JSON, giúp App Widget và dịch vụ nền đọc trực tiếp mà không cần mở CSDL.
5. **Lớp dịch vụ nền Android Native (*Native Android Background Layer*)**: `StepCounterService` là dịch vụ tiền cảnh Kotlin đăng ký cảm biến `Sensor.TYPE_STEP_COUNTER` gom cụm 10 giây. `BootReceiver` tự chạy lại dịch vụ sau khi máy khởi động lại. `FitnessAppWidgetProvider` cập nhật giao diện widget màn hình chính qua `RemoteViews`. Giao tiếp giữa Flutter và Android được thực hiện qua `MethodChannel` và `EventChannel`.
6. **Lớp Cloud Services & External APIs**: `Firebase Authentication` xác thực Google Sign-In; `Cloud Firestore` lưu trữ NoSQL tại `/users/{uid}/{sub_collections}` với cơ chế chia mẻ ghi `WriteBatch` ($\le 400$ thao tác); `Google Generative AI` cung cấp mô hình Gemini 2.5 Flash; `Open Food Facts API` hỗ trợ tra cứu mã vạch.

---

## 2.4. Tổ chức cấu trúc mã nguồn

Mã nguồn được phân tách rõ ràng giữa mã Dart/Flutter trong `lib/` và mã Native Android trong `android/`:

```
fitness_tracker/
├── lib/                               # Mã nguồn Flutter (Dart)
│   ├── main.dart                      # Khởi tạo Firebase, CSDL và dịch vụ
│   ├── theme.dart                     # Design Tokens và giao diện tối AppTheme
│   ├── database/app_database.dart     # SQLite, DDL 7 bảng, index và migration
│   ├── models/                        # Mô hình dữ liệu thuần (Entities)
│   ├── repositories/                  # Kho dữ liệu theo miền và cache RAM
│   ├── services/                      # Dịch vụ ngoài (Gemini, Firestore, Health)
│   ├── screens/                       # Màn hình chính và các thẻ con profile/
│   ├── widgets/                       # Widget dùng chung, CustomPainter, fl_chart
│   └── utils/                         # Tiện ích định dạng và rung AppHaptics
├── android/app/src/main/              # Mã nguồn Native Android (Kotlin)
│   ├── AndroidManifest.xml            # Khai báo quyền, Service, Receiver, Widget
│   ├── kotlin/com/example/fitness_tracker/
│   │   ├── MainActivity.kt            # Cấu hình Channel và Broadcast
│   │   ├── StepCounterService.kt      # Dịch vụ tiền cảnh đếm bước chân native
│   │   ├── BootReceiver.kt            # Phục hồi dịch vụ sau khởi động máy
│   │   └── FitnessAppWidgetProvider.kt# Quản lý RemoteViews của App Widget
│   └── res/                           # Layout XML của Widget và tài nguyên đồ họa
├── assets/i18n/                       # Từ điển bản địa hóa (vi.json, en.json)
└── test/                              # 123 ca kiểm thử tự động (Unit, Widget test)
```

Sự phân tách này mang lại lợi ích kiến trúc rõ ràng:
- Mã Dart trong `lib/` độc lập phần cứng, tập trung vào giao diện và logic tính toán; dễ dàng kiểm thử tự động trên môi trường máy tính qua SQLite in-memory mà không cần thiết bị giả lập.
- Mã Kotlin trong `android/` giải quyết các bài toán hệ điều hành: duy trì dịch vụ chạy nền liên tục với mức tiêu thụ điện năng thấp qua Foreground Service, lắng nghe cảm biến phần cứng và cập nhật `RemoteViews` ngoài màn hình chính Android.

Bảng 2.3: Phân bố cấu trúc thư mục và trách nhiệm thiết kế

| Thư mục | Ngôn ngữ | Trách nhiệm thiết kế chính |
|---|---|---|
| `lib/database/` | Dart | Quản lý kết nối SQLite, DDL 7 bảng, đánh chỉ mục và di trú dữ liệu |
| `lib/models/` | Dart | Định nghĩa lớp dữ liệu cho bài tập, món ăn, tin nhắn và hồ sơ thể trạng |
| `lib/repositories/` | Dart | Cung cấp giao diện truy xuất dữ liệu theo miền, quản lý cache RAM |
| `lib/services/` | Dart | Tích hợp Firebase Auth, Cloud Firestore, Gemini AI, Open Food Facts |
| `lib/screens/` | Dart | Xây dựng 4 màn hình chính và các màn hình phụ (Login, Onboarding) |
| `lib/widgets/` | Dart | Chứa thành phần giao diện: mô hình cấu trúc cơ 2D, biểu đồ `fl_chart`, dock kính |
| `android/.../kotlin/` | Kotlin | Cài đặt `StepCounterService`, `BootReceiver`, `FitnessAppWidgetProvider` |
| `android/.../res/` | XML | Định nghĩa layout widget màn hình chính và tài nguyên đồ họa native |

---

## 2.5. Thiết kế cơ sở dữ liệu và lưu trữ

### 2.5.1. Cơ sở dữ liệu SQLite cục bộ

Hệ thống sử dụng `sqflite` để quản lý CSDL quan hệ `fitness_tracker.db`. Cấu trúc CSDL gồm 7 bảng độc lập, liên kết logic theo trục thời gian ngày (`date` chuỗi chuẩn `YYYY-MM-DD`).

![Hình 2.3: Sơ đồ quan hệ thực thể cơ sở dữ liệu SQLite](img/erd-sqlite.png)

Bảy bảng dữ liệu phản ánh các hoạt động vận động và dinh dưỡng của người dùng:
- `workout_logs`: Lưu lịch sử bài tập, thời lượng (phút), calo, set, rep, tạ, dụng cụ, thời điểm và ngày tập.
- `food_entries`: Lưu các món ăn đã nạp, calo, đạm, đường bột, chất béo, loại bữa ăn, ảnh và ngày ghi nhận.
- `daily_water_history`: Bảng lưu tổng lượng nước theo ngày (số cốc, thể tích ml), khóa chính là chuỗi `date`; được `WaterRepository` dùng khi hợp nhất dữ liệu nước uống từ Firestore.
- `chat_messages`: Bảng lưu tin nhắn hội thoại AI (`user`/`model`), được `ChatRepository` sử dụng; luồng giao diện lưu lịch sử chat qua SharedPreferences (mục 2.5.2).
- `favorite_foods`: Lưu danh mục món ăn ưa thích phục vụ tìm kiếm và nhập nhanh khẩu phần ăn mẫu.
- `body_measurements`: Theo dõi số đo thể trạng theo ngày gồm cân nặng, các vòng cơ thể và tỷ lệ mỡ ước tính.
- `progress_photos`: Lưu nhật ký ảnh chụp tiến trình vóc dáng kèm tư thế, cân nặng và ghi chú cá nhân.

Bảng 2.4: Đặc tả cấu trúc các bảng trong cơ sở dữ liệu SQLite cục bộ

| Tên bảng | Khóa chính (PK) | Các cột dữ liệu chính | Các chỉ mục (Indexes) |
|---|---|---|---|
| `workout_logs` | `id` (INTEGER, Tự tăng) | `title`, `duration`, `calories`, `sets`, `reps`, `weight`, `date` | `idx_workout_date`, `idx_workout_timestamp` |
| `food_entries` | `id` (TEXT, UUID) | `name`, `calories`, `protein`, `carbs`, `fat`, `meal_type`, `date` | `idx_food_date`, `idx_food_timestamp` |
| `daily_water_history` | `date` (TEXT, YYYY-MM-DD) | `cups`, `volume_ml`, `updated_at` | Khóa chính `date` tự động tạo chỉ mục B-tree |
| `chat_messages` | `id` (TEXT, UUID) | `role`, `text`, `timestamp` | `idx_chat_timestamp` |
| `favorite_foods` | `id` (TEXT, UUID) | `name`, `calories`, `protein`, `carbs`, `fat`, `serving_size` | `idx_fav_food_name` |
| `body_measurements` | `id` (TEXT, UUID) | `date`, `weight`, `neck_cm`, `chest_cm`, `waist_cm`, `hips_cm` | `idx_body_meas_date` |
| `progress_photos` | `id` (TEXT, UUID) | `date`, `image_path`, `pose`, `weight`, `notes` | `idx_prog_photo_date` |

Trong luồng sử dụng hằng ngày, `food_entries`, `workout_logs`, `body_measurements`, `favorite_foods` và `progress_photos` là nơi lưu chính; kiểm tra trên thiết bị thật cho thấy các bản ghi món ăn, buổi tập và số đo cơ thể được ghi đúng vào các bảng này.

Để bảo đảm tính liên tục khi nâng cấp từ bản dùng SharedPreferences sang SQLite, lớp `AppDatabase` triển khai phương thức `_migrateFromSharedPreferences()`. Quá trình kiểm tra cờ `sqlite_migrated_v1` và gom dữ liệu vào `db.batch()` để chèn đồng loạt trong một giao dịch duy nhất (*transaction*).

### 2.5.2. Lưu trữ cấu hình và dữ liệu đồng bộ qua SharedPreferences

`SharedPreferences` lưu trữ cấu hình nhẹ và là vùng nhớ chia sẻ liên tiến trình giữa Native Android và Flutter tại tệp XML `/data/data/com.nhh031.fitness_tracker/shared_prefs/FlutterSharedPreferences.xml`.

Bảng 2.5: Danh mục các khóa SharedPreferences dùng chung

| Tên khóa (Key) | Kiểu dữ liệu | Phạm vi sử dụng | Mục đích kỹ thuật |
|---|---|---|---|
| `flutter.today_steps` | Long (Int64) | Kotlin $\leftrightarrow$ Flutter | Lưu tổng số bước chân trong ngày hôm nay |
| `flutter.step_baseline_hardware`, `flutter.step_baseline_date` | Long / String | Kotlin $\leftrightarrow$ Flutter | Mốc số bước phần cứng và ngày lấy mốc |
| `flutter.step_reboot_offset` | Long (Int64) | Kotlin $\leftrightarrow$ Flutter | Số bước bù trừ tích lũy khi thiết bị khởi động lại |
| `flutter.water_cups_today` | Long (Int64) | Flutter $\rightarrow$ App Widget | Số cốc nước hôm nay, hiển thị lên App Widget |
| `flutter.is_guest_mode` | Boolean | Flutter (`AuthGate`) | Đánh dấu người dùng đang sử dụng ở chế độ khách |
| `flutter.biometric_app_lock_enabled` | Boolean | Flutter (`BiometricGate`)| Cờ bật/tắt tính năng khóa bảo mật vân tay |
| `flutter.daily_water_history` | StringList (JSON) | Flutter (`StorageService`) | Lịch sử nước uống theo ngày (tối đa 60 ngày) |
| `flutter.ai_chat_history` | StringList (JSON) | Flutter (`StorageService`) | Lịch sử hội thoại với trợ lý Gemini |
| `flutter.app_language` | String | Flutter (`LocaleService`) | Ngôn ngữ hiển thị (`vi` / `en`) |
| `flutter.user_profile` | String (JSON) | Flutter (`StorageService`)| Chuỗi JSON chứa thông tin thể trạng và mục tiêu calo |
| `flutter.sqlite_migrated_v1` | Boolean | Flutter (`AppDatabase`) | Cờ xác nhận đã hoàn tất di trú dữ liệu sang SQLite |

Do cảm biến bước chân phát sinh sự kiện liên tục, lớp `StepRepository` áp dụng cơ chế trì hoãn ghi đĩa (*debounced I/O*): chỉ ghi xuống tệp XML khi số bước thay đổi từ 3 bước trở lên hoặc sau tối thiểu 2 giây:

```dart
// Debounced disk saving: Giảm thiểu ghi I/O liên tục
final bool shouldPersist = _lastPersistedSteps == null ||
    (calculatedSteps - _lastPersistedSteps!).abs() >= 3 ||
    _lastPersistTime == null ||
    now.difference(_lastPersistTime!).inSeconds >= 2;

if (shouldPersist) {
  _lastPersistedSteps = calculatedSteps;
  _lastPersistTime = now;
  await prefs.setInt(_keyTodaySteps, calculatedSteps);
  await saveDailySteps(todayStr, calculatedSteps);
}
```
(Nguồn: `lib/repositories/step_repository.dart:120-131`)

### 2.5.3. Mô hình lưu trữ đám mây Cloud Firestore

Dịch vụ NoSQL Cloud Firestore sao lưu dự phòng và hỗ trợ chuyển đổi thiết bị. Dữ liệu được tổ chức phân cấp theo định danh người dùng:
- `/users/{uid}`: Hồ sơ người dùng (UserProfile, chuỗi hoạt động Streak).
- `/users/{uid}/food_logs`: Bản sao nhật ký dinh dưỡng.
- `/users/{uid}/workout_logs`: Bản sao lịch sử bài tập.
- `/users/{uid}/water_logs`: Bản sao nhật ký nước uống theo ngày.
- `/users/{uid}/body_measurements`: Bản sao số đo nhân trắc học.
- `/users/{uid}/favorite_foods`: Danh mục món ăn ưa thích.
- `/users/{uid}/ai_chat_history`: Lịch sử hội thoại với trợ lý AI.
- `/users/{uid}/daily_summaries`, `/users/{uid}/settings`: Tổng hợp theo ngày và cấu hình người dùng.

Đồng bộ được thực thi qua phương thức `FirestoreService.syncOnLogin()` khi người dùng đăng nhập Google (ở chế độ Khách, dữ liệu chỉ lưu cục bộ):
1. Đọc song song các bản ghi cục bộ (SQLite, SharedPreferences) và tài liệu tương ứng trên Firestore.
2. Thuật toán hợp nhất hai chiều (*Two-Way Merge*) theo từng loại dữ liệu: nhật ký bài tập và món ăn được hợp theo khóa định danh (bản ghi chỉ có ở một phía được bổ sung sang phía còn lại); nước uống lấy giá trị lớn nhất theo từng ngày; chuỗi ngày (*streak*) lấy giá trị lớn hơn; hồ sơ ưu tiên giá trị trên đám mây nếu có. Kết quả hợp nhất được ghi lại vào bộ nhớ cục bộ và đẩy các bản ghi còn thiếu lên Firestore.
3. Để không vượt ngưỡng giới hạn 500 thao tác của Firestore SDK, hệ thống tự động ngắt mẻ ghi (*batch chunking*) và gọi `commit()` khi đạt mốc 400 thao tác, sau đó khởi tạo mẻ ghi mới để tiếp tục xử lý.

---

## 2.6. Luồng điều hướng và bảo mật ứng dụng

Kiến trúc điều hướng được tổ chức thành chuỗi cổng kiểm soát tuần tự nhằm bảo vệ thông tin cá nhân:

![Hình 2.4: Sơ đồ luồng điều hướng và xác thực ứng dụng](img/luong-dieu-huong.png)

Quy trình điều hướng diễn ra qua năm giai đoạn:
1. **Khởi tạo tại `main()`**: Khởi tạo kết nối Firebase, nạp ngôn ngữ qua `LocaleService`, kết nối CSDL `AppDatabase` và nạp khóa Gemini AI. Lớp `FitnessTrackerApp` lắng nghe ngôn ngữ qua `ValueListenableBuilder`.
2. **Cổng xác thực danh tính (`AuthGate`)**: Widget `StreamBuilder` lắng nghe trạng thái từ `FirebaseAuth.instance.authStateChanges()`. Nếu chưa đăng nhập và cờ `is_guest_mode` chưa bật, ứng dụng hiển thị `LoginScreen`. Khi người dùng đăng nhập Google hoặc chọn tiếp tục với vai trò khách, hệ thống kiểm tra cờ `hasCompletedOnboarding`. Nếu chưa có hồ sơ ban đầu, ứng dụng chuyển hướng đến `OnboardingProfileScreen` để nhập chiều cao, cân nặng và mục tiêu.
3. **Cổng bảo vệ sinh trắc học (`BiometricGate`)**: Bao bọc bên ngoài `MainScreen`; nếu người dùng đã bật khóa sinh trắc học, ứng dụng yêu cầu xác thực bằng `BiometricPrompt` trước khi vào màn hình chức năng (mục 3.8).
4. **Khung điều phối giao diện chính (`MainScreen`)**: Điều phối bốn tab (`Dashboard`, `Workout`, `Food`, `Profile`) bằng `IndexedStack`. Thiết kế này bảo toàn nguyên vẹn trạng thái hiển thị của các màn hình khi người dùng chuyển đổi tab qua dock nổi kính mờ `BackdropFilter`.
5. **Làm mới phiên khi đăng xuất (`Session Invalidation`)**: Khi đăng xuất tại `ProfileScreen`, phương thức `AuthRepository.logout()` kích hoạt giao dịch xóa trắng 7 bảng SQLite, thiết lập lại SharedPreferences và dọn sạch cache RAM. Hệ thống đồng thời đổi khóa phiên (`sessionKey` của `KeyedSubtree` trong `AuthGate`, `UniqueKey` của các tab trong `MainScreen`) nhằm tiêu hủy toàn bộ cây giao diện cũ, ngăn ngừa nguy cơ rò rỉ dữ liệu cá nhân giữa các phiên làm việc.
