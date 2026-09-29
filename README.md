# 🏋️ Fitness Tracker (Fitness App)

Một ứng dụng theo dõi sức khỏe và thể hình thông minh trên nền tảng **Flutter**, tích hợp Huấn luyện viên AI cá nhân hóa (Google Gemini), mô hình giải phẫu động học cử động bài tập chuẩn xác (Kinematic Anatomy Models), đếm bước chân thời gian thực qua Android Foreground Service, tiện ích màn hình chính (Android Home Screen Widget), đồng bộ thiết bị đeo thông minh (Smartwatch qua Health Connect / Apple Health), quét mã vạch dinh dưỡng (Open Food Facts), bảo mật sinh trắc học (Biometric Lock), lưu trữ cục bộ bảo mật SQLite (Local-First Architecture) và đồng bộ đám mây Firebase.

---

## ✨ Tính năng nổi bật

### 🦾 1. Mô hình Giải phẫu Động học Cử động Bài tập (Kinematic Anatomy Models)
- **Mô phỏng 2D sinh cơ học thời gian thực** (`AnatomyKinematicPainter`, `ExercisePoseWidget`): Tái hiện chuyển động khung xương và cơ bắp người tập trực tiếp bằng Vector Canvas mượt mà, không phụ thuộc vào video clip nặng nề.
- **2 góc nhìn trực quan chuyên sâu**: Chuyển đổi linh hoạt giữa góc nhìn **Mặt trước (Frontal View)** và **Mặt bên (Sagittal / Side View)** để quan sát toàn diện phom tập.
- **Chu kỳ nhịp điệu 4 pha chuẩn khoa học (4-Phase Biomechanical Rep Cadence)**:
  - **Pha chuẩn bị (0% – 8%)**: Tư thế đứng/nằm sẵn sàng, căn chỉnh trục cột sống.
  - **Pha hạ có kiểm soát / Eccentric (8% – 46%)**: Di chuyển theo hàm Hermite mượt mà, hạ tạ có kiểm soát.
  - **Pha dừng đỉnh điểm / Isometric Hold (46% – 58%)**: Dừng ~0.35 giây ở điểm sâu nhất của động tác giúp người tập quan sát rõ góc uốn gối, góc hông, cùi chỏ và độ căng cơ bắp.
  - **Pha phát lực / Concentric (58% – 90%)**: Đẩy/kéo phát lực dứt khoát về vị trí ban đầu.
  - **Pha khóa khớp & thở / Lockout (90% – 100%)**: Reset nhịp thở trước khi bắt đầu rep tiếp theo.
- **Bảo toàn chiều dài xương (Constant-Length Bones)**: Tính toán bằng lượng giác học ($\sin / \cos$), giữ nguyên độ dài cẳng chân, đùi, cánh tay, cẳng tay trong suốt chuyển động (loại bỏ hiện tượng xương bị co giãn biến dạng cao su).
- **Phát sáng kích hoạt nhóm cơ mục tiêu (Target Muscle Activation Glow)**: Nhóm cơ tác động chính (Ngực, Đùi trước, Mông, Lưng xô, Vai, Tay trước/sau, Cơ bụng...) phát sáng cường độ cao tại điểm căng tối đa.
- **Thư viện bài tập đa dạng**: Squat, Bench Press, Romanian Deadlift (RDL), Push-up, Diamond Push-up, Dumbbell Row, Overhead Shoulder Press, Bicep Curl, Tricep Extension, Lateral Raise, Lunges, Hip Thrust, Plank, Crunches, Mountain Climbers, Jumping Jacks,...
- **Bảng hướng dẫn kỹ thuật chi tiết (Exercise Guide Sheet)**: Cung cấp đầy đủ hướng dẫn thực hiện từng bước, các lỗi sai thường gặp (Common Mistakes), nhịp thở chuẩn và mẹo thể hình an toàn.

---

### 🤖 2. Huấn luyện viên AI & Phân tích dinh dưỡng (Google Gemini 2.5 Flash)
- **Phân tích hình ảnh món ăn đa phương thức (Multimodal AI Vision)**: Chụp ảnh trực tiếp hoặc chọn từ thư viện, AI tự động nhận diện món ăn và ước lượng Calo, Đạm (Protein), Tinh bột (Carbs), Chất béo (Fat).
- **Trò chuyện & Tư vấn 24/7**: Chatbot AI đóng vai huấn luyện viên thể hình cá nhân hóa, tư vấn dinh dưỡng và lịch tập dựa trên chỉ số sinh trắc học và lịch sử hoạt động thực tế.
- **Bản tin sức khỏe hàng ngày (Daily AI Health Briefing)**: Đánh giá tự động chất lượng ngày tập luyện, giấc ngủ, lượng nước và đưa ra lời khuyên khởi động ngày mới.
- **Bộ nhớ đệm dinh dưỡng thông minh (Zero-latency offline cache)**: Tự động ghi nhớ các món đã tra cứu, truy vấn tức thì kể cả khi mất kết nối mạng.

---

### 🏷️ 3. Quét mã vạch thực phẩm (Barcode Nutrition Scanner)
- Tích hợp camera quét mã vạch thời gian thực (`mobile_scanner`).
- Kết nối trực tiếp cơ sở dữ liệu thực phẩm quốc tế & Việt Nam **Open Food Facts REST API**.
- Tự động bóc tách năng lượng (kcal/kJ), Đạm (Protein), Tinh bột (Carbs), Chất béo (Fat).
- Tùy chỉnh khẩu phần ăn linh hoạt (0.5x, 1x, 1.5x, 2x) và ghi log theo từng bữa (Sáng, Trưa, Tối, Bữa phụ).

---

### 📱 4. Tiện ích Màn hình chính Android (Android Home Screen Widget)
- Tích hợp **Android AppWidget Provider** (`FitnessAppWidgetProvider.kt`): Hiển thị trực tiếp số bước chân hàng ngày (Step Count), tiến độ mục tiêu (%) và lượng calo tiêu hao ra ngay màn hình chính điện thoại mà không cần mở ứng dụng.
- Tự động làm mới và đồng bộ theo thời gian thực mỗi khi có bước chân mới từ Foreground Service.

---

### 🔒 5. Bảo mật Sinh trắc học (Biometric App Lock & Privacy Gate)
- Bảo vệ dữ liệu sức khỏe và hình thể cá nhân bằng dấu vân tay (Fingerprint) hoặc nhận diện khuôn mặt (Face Unlock / Biometrics) qua `local_auth`.
- Tự động kích hoạt màn hình khóa riêng tư (`BiometricGate`) khi ứng dụng tạm ẩn hoặc sau khoảng thời gian chờ an toàn.

---

### ⌚ 6. Đồng bộ thiết bị đeo & Google Health Connect / Apple Health
- Tự động đọc dữ liệu bước chân, nhịp tim (Heart Rate), thời lượng giấc ngủ (Sleep) và calo tiêu hao từ Smartwatch (Samsung Galaxy Watch, Apple Watch, Garmin, Xiaomi Mi Band,...).
- Thẻ quản lý đồng bộ trực quan trong màn hình Hồ sơ với nút "ĐỒNG BỘ NGAY".

---

### 🚶 7. Đếm bước chân nền bền vững (Persistent Background Step Tracker)
- Sử dụng Android Foreground Service kết hợp cảm biến phần cứng chuyên dụng của thiết bị.
- Tích hợp bộ lọc chống rung xe (Anti-Jitter) và cơ chế lưu trữ bảo toàn số bước kể cả khi thiết bị khởi động lại (Reboot resilience).

---

### 🗄️ 8. Kiến trúc Local-First SQLite Database
- Lưu trữ độc lập toàn bộ lịch sử tập luyện, nhật ký dinh dưỡng, nước uống và hội thoại AI vào cơ sở dữ liệu SQLite (`sqflite`).
- Thiết kế theo mô hình Repository Pattern chuẩn mực (`WorkoutRepository`, `NutritionRepository`, `WaterRepository`, `ChatRepository`, `StepRepository`, `AuthRepository`).

---

### 💧 9. Theo dõi Nước uống (Hydration) & Sức khỏe toàn diện
- Ghi nhận lượng nước uống theo cốc/ml, tùy chỉnh lời nhắc uống nước định kỳ thông minh kèm phản hồi rung Haptic.
- **Điểm Sức Khỏe Toàn Diện (Holistic Health Score)**: Thuật toán chấm điểm dựa trên 5 trụ cột: Vận động, Giấc ngủ, Nước uống, Dinh dưỡng và Tỷ lệ Calo tiêu thụ/nạp.
- Tính toán TDEE, BMR, Calorie Deficit/Surplus và phân bổ Macro phù hợp mục tiêu: Siết mỡ (Cutting), Tăng cơ (Bulking), Bền bỉ (Endurance), Cân bằng (Balanced).
- Hệ thống huy hiệu thành tích (Achievement Badges) và chuỗi ngày rèn luyện liên tục (Streaks).
- Đa ngôn ngữ: Chuyển đổi linh hoạt giữa Tiếng Việt và English.
- Hỗ trợ đăng nhập Google Sign-In, Firebase Auth hoặc Chế độ Khách (Guest Mode) không cần tài khoản.

---

## 📱 HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG TRÊN MÁY THẬT ANDROID

Để sử dụng đầy đủ các cảm biến phần cứng (Camera quét mã vạch, Cảm biến bước chân, Đồng bộ Smartwatch qua Health Connect, Chạy nền không bị tắt, Widget màn hình chính), **bạn nên cài đặt trực tiếp lên điện thoại Android thật**.

### Bước 1: Chuẩn bị trên điện thoại Android

1. **Bật Tùy chọn nhà phát triển (Developer Options)**:
   - Vào **Cài đặt (Settings)** -> **Thông tin điện thoại (About phone)**.
   - Tìm mục **Số bản dựng (Build number)** và **nhấn liên tục 7 lần** cho đến khi xuất hiện thông báo: *"Bạn đã là nhà phát triển!"*.
2. **Bật Gỡ lỗi qua USB (USB Debugging)**:
   - Quay lại Cài đặt -> vào **Tùy chọn nhà phát triển (Developer options)**.
   - Bật mục **Gỡ lỗi qua USB (USB debugging)**.
   - *(Lưu ý đối với máy Xiaomi/Redmi/POCO, Realme, Oppo, Vivo)*: Hãy bật thêm tùy chọn **Cài đặt qua USB (Install via USB)** để máy tính có thể cài ứng dụng trực tiếp.

### Bước 2: Kết nối điện thoại với máy tính

1. Sử dụng cáp USB cắm nối điện thoại với máy tính.
2. Trên thanh thông báo điện thoại, chọn chế độ USB là **Truyền tệp (File Transfer / MTP)**.
3. Trên màn hình điện thoại sẽ hiện hộp thoại xác nhận: **"Cho phép gỡ lỗi USB từ máy tính này?"**
   - Tích chọn: **"Luôn cho phép từ máy tính này" (Always allow from this computer)**.
   - Bấm **Cho phép (Allow / OK)**.
4. Mở Terminal trên máy tính và kiểm tra kết nối:
   ```bash
   flutter devices
   ```
   *Bạn sẽ thấy tên điện thoại thật hiển thị (Ví dụ: `SM-G998B`, `Xiaomi 2201116SG`, hoặc `Pixel 7`).*

---

### Bước 3: Cấu hình biến môi trường (`.env`)

Tạo file `.env` tại thư mục gốc của dự án (nếu chưa có):
```bash
cp .env.example .env
```
Mở file `.env` và điền API Key từ [Google AI Studio](https://aistudio.google.com/):
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

---

### Bước 4: Chạy ứng dụng lên điện thoại

#### Cách 1: Chạy trực tiếp qua lệnh Flutter (khuyên dùng khi phát triển/test)
Chạy lệnh sau trong thư mục dự án:
```bash
flutter run --dart-define-from-file=.env
```
*(Nếu máy tính nhận nhiều thiết bị cùng lúc, thêm cờ `-d <DEVICE_ID>`, ví dụ: `flutter run -d R5CR30XXXXX --dart-define-from-file=.env`)*.

---

#### Cách 2: Biên dịch file APK để cài đặt độc lập (không cần cắm cáp máy tính)

Bạn có thể xuất file APK tối ưu dung lượng theo từng kiến trúc CPU bằng cờ `--split-per-abi` (giúp file APK chỉ ~97MB thay vì file universal 270MB):

1. **Biên dịch bản Debug APK (nhanh chóng, đầy đủ log debug):**
   ```bash
   flutter build apk --debug --split-per-abi --dart-define-from-file=.env
   ```
   📁 File tạo ra tại: `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` (hoặc `app-armeabi-v7a-debug.apk` / `app-x86_64-debug.apk`)

2. **Hoặc biên dịch bản Release APK (tối ưu hóa tốc độ, dung lượng gọn nhẹ):**
   ```bash
   flutter build apk --release --split-per-abi --dart-define-from-file=.env
   ```
   📁 File tạo ra tại: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

3. **Cài đặt vào điện thoại:**
   - Chép file `.apk` vào điện thoại (qua dây cáp, Zalo, Google Drive).
   - Mở ứng dụng **Quản lý tệp (File Manager)** trên điện thoại, tìm file APK và nhấn **Cài đặt**.
   - Nếu hệ điều hành hỏi *"Cho phép cài đặt ứng dụng từ nguồn này"*, hãy chọn **Cho phép / Bật**.

---

### Bước 5: Cấp các quyền quan trọng trên máy thật để app hoạt động chuẩn 100%

Khi mở app lần đầu trên điện thoại, hãy cấp các quyền sau để trải nghiệm trọn vẹn:
1. **Camera**: Cấp quyền khi bấm "Quét mã vạch" hoặc "Chụp món ăn AI".
2. **Hoạt động thể chất (Physical Activity)**: Cho phép app truy cập cảm biến đếm bước chân phần cứng của điện thoại.
3. **Tối ưu hóa Pin (Ignore Battery Optimizations)**:
   - Vào tab **Hồ sơ (Profile)** -> Tìm thẻ **Chạy nền & Tối ưu hóa pin** -> Bấm **CẤP QUYỀN CHẠY NỀN**.
   - Chọn *"Không hạn chế / Cho phép chạy nền"* để điện thoại không tự tắt bộ đếm bước chân khi bạn tắt màn hình hoặc bỏ điện thoại vào túi quần.
4. **Google Health Connect (Kết nối Smartwatch)**:
   - Với Android 14 trở lên: Đã tích hợp sẵn trong Cài đặt hệ thống.
   - Với Android 13 trở xuống: Tải miễn phí ứng dụng [Health Connect](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata) từ Google Play Store.
   - Vào tab **Hồ sơ** -> Bấm **KẾT NỐI HEALTH CONNECT / WATCH** -> Tích chọn cho phép quyền đọc Bước chân, Nhịp tim, Giấc ngủ, Năng lượng tiêu hao.
5. **Thêm Tiện ích Màn hình chính (Widget)**:
   - Ngoài màn hình chính điện thoại, nhấn giữ vào khoảng trống -> Chọn **Tiện ích (Widgets)** -> Tìm **Fitness Tracker** -> Kéo thả widget ra màn hình để theo dõi bước chân trực tiếp.

---

## 🧪 Kiểm thử tự động & Tiêu chuẩn chất lượng (Testing)

Dự án tuân thủ nghiêm ngặt nguyên tắc **Zero Regression** và kiểm soát chất lượng mã nguồn:

```bash
# 1. Kiểm tra phân tích tĩnh mã nguồn (0 issues found)
flutter analyze

# 2. Chạy toàn bộ 123+ bài kiểm thử tự động (Unit & Widget Tests)
flutter test
```

- **Kết quả kiểm thử**: 123/123 bài test vượt qua (100% Passed).
- **Phạm vi kiểm thử**:
  - Động học giải phẫu & nhịp điệu bài tập (`anatomy_kinematic_painter_test.dart`, `exercise_pose_widget_test.dart`).
  - Bản đồ cơ bắp 2D tương tác (`muscle_anatomy_map_test.dart`).
  - Điểm số sức khỏe toàn diện (`health_score_test.dart`).
  - Bản tin sức khỏe hàng ngày AI (`daily_ai_briefing_test.dart`).
  - Ghi nhận dinh dưỡng, nước uống, streak ngày liên tục (`storage_service_test.dart`).
  - Đồng bộ thiết bị đeo qua Health Connect (`phase_4_features_test.dart`).

---

## 📁 Cấu trúc thư mục dự án

```
lib/
├── main.dart                  # Khởi tạo App, Database, Firebase, Health, Locale, Widget Sync
├── theme.dart                 # Cyber Dark Theme & Typographic tokens
├── database/
│   └── app_database.dart      # Quản lý SQLite database, migration & schema
├── repositories/              # Repository Pattern tách biệt nghiệp vụ
│   ├── auth_repository.dart
│   ├── chat_repository.dart
│   ├── nutrition_repository.dart
│   ├── step_repository.dart
│   ├── water_repository.dart
│   └── workout_repository.dart
├── models/                    # Data models: UserProfile, FoodLogEntry, DailyWaterLog, Badge...
├── screens/                   # Các màn hình chính (Dashboard, Workout, Food, Profile...)
│   └── profile/               # Các module thẻ chức năng màn hình Hồ sơ
├── services/                  # HealthSyncService, OpenFoodFactsService, GeminiService, StorageService...
├── utils/                     # Formatters, AppHaptics, Helpers
└── widgets/                   # AnatomyKinematicPainter, ExercisePoseWidget, BiometricGate,
                               # BarcodeScannerSheet, DonutChart, DailyAiBriefing, WaterReminderWidget...
android/
└── app/src/main/kotlin/.../
    └── FitnessAppWidgetProvider.kt # Android AppWidget Provider cập nhật bước chân ra Home Screen
```
