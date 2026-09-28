# 🏋️ Fitness Tracker (Fitness App)

Một ứng dụng theo dõi sức khỏe và thể hình thông minh trên nền tảng **Flutter**, tích hợp AI Coach cá nhân hóa (Google Gemini), đếm bước chân thời gian thực qua Android Foreground Service, đồng bộ đám mây Firebase và tính toán chỉ số dinh dưỡng khoa học (TDEE, BMR theo Mifflin-St Jeor).

---

## ✨ Tính năng nổi bật

- 🤖 **Huấn luyện viên AI & Phân tích dinh dưỡng (Google Gemini 2.5 Flash)**:
  - Phân tích hình ảnh món ăn đa phương thức (Multimodal AI Vision).
  - Trò chuyện và tư vấn dinh dưỡng theo thời gian thực dựa trên chỉ số sinh trắc học cá nhân.
  - Bản tin sức khỏe hàng ngày (Daily AI Health Briefing) tự động đánh giá ngày hôm trước.
  - Bộ nhớ đệm dinh dưỡng thông minh (Zero-latency offline cache) giúp truy vấn tức thì kể cả khi mất mạng.
- 🚶 **Đếm bước chân bền vững (Persistent Background Step Tracker)**:
  - Tích hợp Android Foreground Service + Cảm biến phần cứng.
  - Bộ lọc chống giật và bảo toàn số bước kể cả khi thiết bị khởi động lại (Reboot resilience).
- 💧 **Theo dõi Hydration (Uống nước)**:
  - Ghi nhận lượng nước uống theo cốc/ml, tùy chỉnh lời nhắc uống nước định kỳ.
- 🍎 **Quản lý dinh dưỡng & Cân bằng năng lượng**:
  - Tính toán TDEE, BMR, Calorie Deficit/Surplus và phân bổ Macro (Protein, Carbs, Fat) phù hợp với mục tiêu: Siết mỡ (Cutting), Tăng cơ (Bulking), Bền bỉ (Endurance), Cân bằng (Balanced).
- 🏆 **Huy hiệu thành tích (Achievement System)**:
  - Hệ thống huy hiệu rèn luyện kỷ luật, chuỗi ngày liên tục (Streaks), và tự động chúc mừng khi đạt mốc.
- 🌐 **Hỗ trợ song ngữ**:
  - Chuyển đổi mượt mà giữa Tiếng Việt và English.
- ☁️ **Đồng bộ đám mây**:
  - Đăng nhập Google Sign-In & Firebase Auth, đồng bộ dữ liệu tự động với Cloud Firestore.

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy

### 1. Cấu hình Gemini API Key

Dự án sử dụng cơ chế bảo mật biến môi trường để không lộ API Key lên mã nguồn Git.

Sao chép file template:
```bash
cp .env.example .env
```
Mở file `.env` và điền Gemini API Key lấy từ [Google AI Studio](https://aistudio.google.com/):
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### 2. Khởi chạy ứng dụng

**Chạy với VS Code**:
- Nhấn `F5` hoặc chọn Run Configuration: `Fitness Tracker (Debug with .env)`.

**Chạy qua Terminal**:
```bash
# Nạp trực tiếp từ file .env
flutter run --dart-define-from-file=.env

# Hoặc truyền trực tiếp qua cờ dart-define
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

---

## 🧪 Kiểm thử (Testing)

Dự án được bao phủ kiểm thử tự động với bộ test suite toàn diện:

```bash
# Kiểm tra phân tích mã nguồn
flutter analyze

# Chạy toàn bộ 80 unit & widget tests
flutter test
```

---

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart              # Khởi tạo Firebase, Auth, Notification, Locale & App
├── theme.dart             # Dark Theme & Typographic tokens
├── models/                # UserProfile, FitnessBadge, AchievementBadge
├── screens/               # Dashboard, Workout, Food, Profile, Login, Onboarding
├── services/              # GeminiService, StorageService, AuthService, FirestoreService...
├── utils/                 # AppFormatters, AppHaptics
└── widgets/               # Macro donut chart, Calorie balance hero, Daily AI briefing...
```
