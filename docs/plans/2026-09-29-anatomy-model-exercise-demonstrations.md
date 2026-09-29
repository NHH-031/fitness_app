# Kế Hoạch Hiện Thực Hóa: Dùng Mô Hình Giải Phẫu Làm Động Tác Mẫu (Anatomy Kinetic Exercise Demonstrator)

> **Mục tiêu:** Thay thế hoàn toàn hình nhân người que (stick figure) đơn điệu hiện tại bằng chính **mô hình cơ bắp giải phẫu thể thao đa tầng (Nam ♂ & Nữ ♀)** đã thiết kế trên Bản Đồ Giải Phẫu, mô phỏng sinh động động tác tập luyện với hiệu ứng cơ bắp co bóp phát sáng thời gian thực (Dynamic Muscle Activation Glow).

**Kiến trúc:** 
- Xây dựng hệ thống khung xương động học vector (`AnatomyKinematicRig`) cho phép các bộ phận cơ thể (ngực, bụng 6 múi/số 11, cơ xô, tay trước/sau, đùi trước/sau, bắp chân) di chuyển theo khớp quay tự nhiên.
- Tự động đồng bộ theo giới tính người dùng (Nam Cyan `#00F0FF`, Nữ Neon Rose `#FF2E93`).
- Tích hợp hiệu ứng phát quang tại đỉnh điểm co cơ (Concentric Peak Contraction) giúp người dùng nhận biết ngay nhóm cơ nào đang được kích hoạt tối đa.

**Công nghệ sử dụng:** Flutter CustomPainter, Path Morphing, AnimationController với Easing Curve, Canvas Shader & MaskFilter Glow, HugeIcons.

---

### Task 1: Thiết kế Bộ Khối Cơ Giải Phẫu Động Học (`AnatomyKinematicPainter`)
**Mục tiêu:** Tạo các hàm vẽ từng khối cơ bắp giải phẫu có thể xoay quanh tâm khớp (Pivot Points) thay vì các đường thẳng đơn sơ.

**Các file liên quan:**
- Tạo mới: `lib/widgets/anatomy_kinematic_painter.dart`
- Test: `test/anatomy_kinematic_painter_test.dart`

**Nội dung công việc:**
1. Tạo cấu trúc dữ liệu mô tả các khớp (Joints): Vai, Khuỷu tay, Cổ tay, Khớp háng, Khớp gối, Cổ chân, Cột sống.
2. Vẽ các mảng cơ giải phẫu thể thao dựa trên các Path từ `MuscleAnatomyMapWidget`:
   - **Thân trên:** Tấm ngực (Pectoralis plates), cơ xô chữ V (Lats), cơ vai hình giọt nước (Deltoids), bắp tay trước (Biceps) và tay sau (Triceps).
   - **Thân giữa:** Cơ bụng 6 múi chia rãnh sâu (Nam) hoặc cơ bụng số 11 thon gọn (Nữ), rãnh liên sườn (Serratus).
   - **Thân dưới:** Cơ mông quả đào căng tròn (Gluteus), khối cơ tứ đầu đùi (Quads), đùi sau (Hamstrings) và bắp chuối (Calves).
3. Hỗ trợ góc nhìn nghiêng (Side/Profile view) và góc nhìn chính diện (Front view) cho từng loại bài tập.

---

### Task 2: Hiện thực hóa Chuyển động Động tác (Kinematic Exercise Algorithms)
**Mục tiêu:** Lập trình quỹ đạo chuyển động mượt mà cho 15+ bài tập thể trọng và tạ đơn phổ biến nhất.

**Các file liên quan:**
- Bổ sung vào: `lib/widgets/anatomy_kinematic_painter.dart`
- Tích hợp vào: `lib/widgets/exercise_pose_widget.dart`

**Danh mục bài tập chuyển động:**
1. **Bài tập chân & mông (Lower Body):**
   - *Squat / Sumo Squat*: Thân trên gập nhẹ, hông đẩy lùi, gối mở góc 90 độ, cơ đùi và mông căng giãn rồi siết mạnh.
   - *Barbell / Dumbbell Hip Thrust*: Nằm tựa lưng, nâng hông tạo đường thẳng, cơ mông bừng sáng ở đỉnh.
   - *Romanian Deadlift (RDL)*: Gập hông đẩy mông ra sau, lưng giữ thẳng, đùi sau căng hết cỡ.
   - *Bulgarian Split Squat & Lunges*: Chân trước gập gối 90 độ, chân sau hạ thấp có kiểm soát.
   - *Standing Calf Raise*: Nhón gót chân lên cao, bắp chuối co rút đỉnh điểm.
2. **Bài tập đẩy thân trên (Upper Push):**
   - *Push-ups (Hít đất)* & *Diamond Push-ups*: Toàn thân thẳng tắp như tấm ván, hạ ngực sát sàn rồi đẩy bung lên.
   - *Dumbbell Bench/Floor Press*: Đẩy hai tạ từ mạn ngực lên trần nhà, ngực ép vào nhau.
   - *Overhead Shoulder Press*: Đẩy tạ thẳng qua đầu, cơ vai trước và giữa kích hoạt.
   - *Overhead Triceps Extension*: Khép cùi chỏ, duỗi cẳng tay sau đầu.
3. **Bài tập kéo thân trên (Upper Pull):**
   - *Pull-ups (Hít xà)*: Kéo cằm vượt thanh xà, xô lưng co bóp tối đa.
   - *Dumbbell Bent-Over Row*: Kéo tạ sát sườn, siết bả vai.
   - *Bicep Curls*: Cuốn tạ, chuột bắp tay cuộn tròn.
4. **Bài tập cơ lõi & Cardio (Core & Full Body):**
   - *Plank*: Giữ tư thế tĩnh vững chắc, nhịp thở vi mô (micro-breathing pulse).
   - *Crunches (Gập bụng)*: Cuộn xương ức về phía xương mu, múi bụng co lại.
   - *Jumping Jacks*: Bật nhảy nhịp nhàng tách chân và vung tay.

---

### Task 3: Hiệu ứng Co bóp Cơ bắp Phát sáng (Dynamic Muscle Activation Glow)
**Mục tiêu:** Tạo điểm nhấn trực quan giúp người dùng hiểu chính xác cơ nào đang co bóp và chịu lực lớn nhất ở từng thời điểm.

**Các file liên quan:**
- File: `lib/widgets/anatomy_kinematic_painter.dart`

**Nội dung công việc:**
1. Khai báo chỉ số kích hoạt cơ `muscleActivationFactor(double progress, ExerciseType type)`.
2. Tạo lớp phủ phát sáng Neon Shader (Cyan với Nam, Neon Rose với Nữ) trên vùng cơ mục tiêu.
3. Khi động tác tiến vào pha co cơ đỉnh điểm (Peak Contraction), vùng cơ đó sẽ phát sáng bừng lên với hiệu ứng `MaskFilter.blur(BlurStyle.normal, 12)` và độ đậm của màu tăng từ 15% lên 90%.

---

### Task 4: Nâng cấp `ExercisePoseAnimator` & Đồng bộ Giới tính Toàn Diện
**Mục tiêu:** Đưa mô hình giải phẫu động học vào mọi nơi trong ứng dụng đang cần hiển thị động tác mẫu.

**Các file liên quan:**
- Chỉnh sửa: `lib/widgets/exercise_pose_widget.dart`
- Chỉnh sửa: `lib/widgets/exercise_guide_sheet.dart`
- Chỉnh sửa: `lib/screens/workout_screen.dart`
- Chỉnh sửa: `lib/screens/active_workout_screen.dart`

**Nội dung công việc:**
1. Thêm tham số `isMale` vào `ExercisePoseAnimator(exerciseTitle: ..., isMale: _isMale)`.
2. Trong `ExerciseGuideSheet` (màn hình hướng dẫn kỹ thuật chi tiết khi chạm vào bản đồ giải phẫu), bổ sung ngay `ExercisePoseAnimator` kích thước lớn (chiều cao 160dp) ở đầu sheet để người dùng vừa đọc kỹ thuật vừa xem mô hình người giải phẫu tập động tác.
3. Trong `WorkoutScreen` và `ActiveWorkoutScreen`, truyền giới tính hiện tại của người dùng vào `ExercisePoseAnimator`.

---

### Task 5: Viết Kiểm Thử, Phân Tích & Xác Thực Trên Android Emulator
**Mục tiêu:** Đảm bảo hệ thống mượt mà 60 FPS, không lỗi logic hay lint, và đạt độ thẩm mỹ đỉnh cao.

**Các file liên quan:**
- Test: `test/anatomy_kinematic_painter_test.dart`
- Test: `test/exercise_pose_widget_test.dart`

**Các bước thực hiện:**
1. Chạy `flutter test` đảm bảo vượt qua 100% test cases (bao gồm các test case mới).
2. Chạy `flutter analyze` đảm bảo 0 cảnh báo lint.
3. Khởi chạy trên Android Emulator (`emulator-5554`), kiểm tra trực tiếp:
   - Nam tập Hít đất, Squat, Đẩy ngực, Kéo xà (Tone Cyan).
   - Nữ tập Hip Thrust, Bulgarian Split Squat, RDL, Plank (Tone Neon Rose).
4. Commit và push code lên GitHub với mô tả chi tiết.
