# 🏋️ Fitness Tracker (Fitness App)

Một ứng dụng theo dõi sức khỏe và thể hình thông minh trên nền tảng **Flutter**, tích hợp Huấn luyện viên AI cá nhân hóa (Google Gemini), đếm bước chân thời gian thực qua Android Foreground Service, đồng bộ thiết bị đeo thông minh (Smartwatch qua Health Connect / Apple Health), quét mã vạch dinh dưỡng (Open Food Facts), lưu trữ cục bộ bảo mật SQLite (Local-First Architecture) và đồng bộ đám mây Firebase.

---

## ✨ Tính năng nổi bật

- 🤖 **Huấn luyện viên AI & Phân tích dinh dưỡng (Google Gemini 2.5 Flash)**:
  - Phân tích hình ảnh món ăn đa phương thức (Multimodal AI Vision).
  - Trò chuyện và tư vấn dinh dưỡng theo thời gian thực dựa trên chỉ số sinh trắc học cá nhân.
  - Bản tin sức khỏe hàng ngày (Daily AI Health Briefing) tự động đánh giá ngày hôm trước.
  - Bộ nhớ đệm dinh dưỡng thông minh (Zero-latency offline cache) giúp truy vấn tức thì kể cả khi mất mạng.
- 🏷️ **Quét mã vạch thực phẩm (Barcode Nutrition Scanner)**:
  - Tích hợp camera quét mã vạch thời gian thực (`mobile_scanner`).
  - Kết nối trực tiếp cơ sở dữ liệu quốc tế & Việt Nam **Open Food Facts REST API**.
  - Tự động bóc tách năng lượng (kcal/kJ), Đạm (Protein), Tinh bột (Carbs), Chất béo (Fat).
  - Tự do tùy chỉnh khẩu phần ăn (0.5x, 1x, 1.5x, 2x) và ghi log theo từng bữa ăn (Sáng, Trưa, Tối, Phụ).
- ⌚ **Đồng bộ thiết bị đeo & Google Health Connect / Apple Health**:
  - Tự động lấy dữ liệu bước chân, nhịp tim (Heart Rate), thời lượng giấc ngủ (Sleep) và calo tiêu hao từ Smartwatch (Samsung Galaxy Watch, Apple Watch, Garmin, Xiaomi Mi Band,...).
  - Thẻ quản lý đồng bộ trực quan trong màn hình Hồ sơ với nút "ĐỒNG BỘ NGAY".
- 🚶 **Đếm bước chân bền vững (Persistent Background Step Tracker)**:
  - Tích hợp Android Foreground Service + Cảm biến phần cứng chuyên dụng.
  - Bộ lọc chống rung xe (Anti-Jitter) và bảo toàn số bước kể cả khi thiết bị khởi động lại (Reboot resilience).
- 🗄️ **Kiến trúc Local-First SQLite Database**:
  - Lưu trữ độc lập toàn bộ lịch sử tập luyện, nhật ký dinh dưỡng, nước uống và đoạn chat AI vào cơ sở dữ liệu SQLite (`sqflite`).
  - Thiết kế theo mẫu Repository Pattern (`WorkoutRepository`, `NutritionRepository`, `WaterRepository`, `ChatRepository`, `StepRepository`, `AuthRepository`).
- 💧 **Theo dõi Hydration (Uống nước)**:
  - Ghi nhận lượng nước uống theo cốc/ml, tùy chỉnh lời nhắc uống nước định kỳ thông minh.
- 🍎 **Quản lý dinh dưỡng & Cân bằng năng lượng**:
  - Tính toán TDEE, BMR, Calorie Deficit/Surplus và phân bổ Macro phù hợp với mục tiêu: Siết mỡ (Cutting), Tăng cơ (Bulking), Bền bỉ (Endurance), Cân bằng (Balanced).
- 🏆 **Huy hiệu thành tích (Achievement System)**:
  - Hệ thống huy hiệu rèn luyện kỷ luật, chuỗi ngày liên tục (Streaks) và tự động vinh danh khi hoàn thành mục tiêu.
- 🌐 **Hỗ trợ đa ngôn ngữ**:
  - Chuyển đổi linh hoạt giữa Tiếng Việt và English.
- ☁️ **Đồng bộ đám mây & Chế độ khách (Guest Mode)**:
  - Đăng nhập Google Sign-In & Firebase Auth, đồng bộ dữ liệu tự động với Cloud Firestore hoặc sử dụng chế độ Khách không cần tài khoản.
- 🔄 **Quy trình CI/CD tự động**:
  - GitHub Actions (`.github/workflows/flutter_ci.yml`) tự động phân tích code (`flutter analyze`), chạy kiểm thử 105+ bài test và build APK.

---

## 📱 HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG TRÊN MÁY THẬT ANDROID

Để sử dụng đầy đủ các cảm biến phần cứng (Camera quét mã vạch, Cảm biến bước chân, Đồng bộ Smartwatch qua Health Connect, Chạy nền không bị tắt), **bạn nên cài đặt trực tiếp lên điện thoại Android thật**.

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

Bạn có thể xuất file APK và gửi qua Zalo/Google Drive hoặc chép vào thẻ nhớ điện thoại để cài đặt:

1. **Biên dịch bản Debug APK (nhanh chóng, đầy đủ log debug):**
   ```bash
   flutter build apk --debug --dart-define-from-file=.env
   ```
   📁 File tạo ra tại: `build/app/outputs/flutter-apk/app-debug.apk`

2. **Hoặc biên dịch bản Release APK (tối ưu hóa tốc độ, dung lượng gọn nhẹ):**
   ```bash
   flutter build apk --release --dart-define-from-file=.env
   ```
   📁 File tạo ra tại: `build/app/outputs/flutter-apk/app-release.apk`

3. **Cài đặt vào điện thoại:**
   - Chép file `.apk` vào điện thoại.
   - Mở ứng dụng **Quản lý tệp (File Manager)** trên điện thoại, tìm file APK và nhấn **Cài đặt**.
   - Nếu hệ điều hành hỏi *"Cho phép cài đặt ứng dụng từ nguồn này"*, hãy chọn **Cho phép / Bật**.

---

### Bước 5: Cấp các quyền quan trọng trên máy thật để app hoạt động chuẩn 100%

Khi mở app lần đầu trên điện thoại, hãy cấp các quyền sau để trải nghiệm trọn vẹn:
1. **Camera**: Cấp quyền khi bấm "Quét mã vạch" hoặc "Chụp món ăn AI".
2. **Hoạt động thể chất (Physical Activity)**: Cho phép app truy cập cảm biến đếm bước chân phần cứng của điện thoại.
3. **Tối ưu hóa Pin (Ignore Battery Optimizations)**:
   - Vào tab **Hồ sơ (Profile)** -> Tìm thẻ **Chạy nền & Tối ưu hóa pin** -> Bấm **CẤP QUYỀN CHẠY NGẦN**.
   - Chọn *"Không hạn chế / Cho phép chạy nền"* để điện thoại không tự tắt bộ đếm bước chân khi bạn tắt màn hình hoặc bỏ điện thoại vào túi quần.
4. **Google Health Connect (Kết nối Smartwatch)**:
   - Với Android 14 trở lên: Đã tích hợp sẵn trong Cài đặt hệ thống.
   - Với Android 13 trở xuống: Tải miễn phí ứng dụng [Health Connect](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata) từ Google Play Store.
   - Vào tab **Hồ sơ** -> Bấm **KẾT NỐI HEALTH CONNECT / WATCH** -> Tích chọn cho phép quyền đọc Bước chân, Nhịp tim, Giấc ngủ, Năng lượng tiêu hao.

---

## 🧪 Kiểm thử tự động (Testing)

Dự án duy trì tiêu chuẩn kỹ thuật cao với chính sách **0 issue lint** và **Zero Regression**:

```bash
# Kiểm tra phân tích chất lượng code (0 issues found)
flutter analyze

# Chạy toàn bộ 105+ bài kiểm thử tự động
flutter test
```

---

## 📁 Cấu trúc thư mục dự án

```
lib/
├── main.dart                  # Khởi tạo App, Database, Firebase, Health, Locale
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
├── models/                    # Data models: UserProfile, FoodLogEntry, Badge...
├── screens/                   # Các màn hình chính (Dashboard, Workout, Food, Profile...)
│   └── profile/               # Các module thẻ chức năng màn hình Hồ sơ
├── services/                  # HealthSyncService, OpenFoodFactsService, GeminiService...
├── utils/                     # Formatters, AppHaptics, Helpers
└── widgets/                   # BarcodeScannerSheet, DonutChart, DailyAiBriefing...
```
