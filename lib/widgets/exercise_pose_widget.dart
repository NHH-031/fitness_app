import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/locale_service.dart';
import 'anatomy_kinematic_painter.dart';

class ExerciseGuideData {
  final String title;
  final String targetMuscles;
  final List<String> steps;
  final String breathingTip;
  final IconData mainIcon;
  final Color themeColor;
  final bool isDumbbell;

  const ExerciseGuideData({
    required this.title,
    required this.targetMuscles,
    required this.steps,
    required this.breathingTip,
    required this.mainIcon,
    required this.themeColor,
    this.isDumbbell = false,
  });

  static ExerciseGuideData getForExercise(String title) {
    final lower = title.toLowerCase();
    final isVi = LocaleService.isVietnamese;

    // Dumbbell 1: Chest Press / Floor Press
    if (lower.contains('floor press') || lower.contains('bench press') || lower.contains('đẩy ngực')) {
      return ExerciseGuideData(
        title: isVi ? 'Đẩy ngực tạ đơn' : 'Dumbbell Floor/Bench Press',
        targetMuscles: isVi
            ? 'Cơ ngực lớn, bắp tay sau & cơ vai trước'
            : 'Pectoralis Major, Triceps & Anterior Deltoids',
        steps: isVi
            ? [
                'Nằm ngửa trên sàn hoặc ghế vát, hai tay cầm tạ ngang ngực, khuỷu tay mở góc 75 độ.',
                'Gồng cơ bụng, dùng lực cơ ngực đẩy mạnh hai quả tạ thẳng lên trần nhà.',
                'Siết chặt ngực ở đỉnh 1 giây, sau đó hạ tạ từ từ xuống có kiểm soát.',
              ]
            : [
                'Lie flat on the floor or bench holding dumbbells at chest level with elbows at 75 degrees.',
                'Brace core and press dumbbells forcefully upward toward the ceiling.',
                'Squeeze chest at the top for 1 second, then lower down under control.',
              ],
        breathingTip: isVi
            ? 'Hít sâu khi hạ tạ mở rộng lồng ngực - Thở mạnh ra khi đẩy tạ lên cao.'
            : 'Inhale as you lower weights - Exhale forcefully as you press upward.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFFF2D55),
        isDumbbell: true,
      );
    }
    // Dumbbell 2: Shoulder Press
    else if (lower.contains('shoulder press') || lower.contains('đẩy vai')) {
      return ExerciseGuideData(
        title: isVi ? 'Đẩy vai tạ đơn qua đầu' : 'Dumbbell Shoulder Press',
        targetMuscles: isVi
            ? 'Cơ vai toàn diện, cơ cầu vai & bắp tay sau'
            : 'Deltoids, Trapezius & Triceps',
        steps: isVi
            ? [
                'Đứng thẳng hoặc ngồi thẳng lưng, đưa hai quả tạ lên ngang tầm tai, lòng bàn tay hướng tới trước.',
                'Đẩy tạ dứt khoát thẳng lên trên đỉnh đầu mà không khóa cứng khớp khuỷu tay.',
                'Hạ tạ chậm rãi trong 2-3 giây về vị trí ngang tai rồi tiếp tục lần lặp tiếp theo.',
              ]
            : [
                'Stand or sit upright with dumbbells at ear level, palms facing forward.',
                'Press dumbbells smoothly straight overhead without locking out elbows.',
                'Lower weights slowly over 2-3 seconds back to ear level.',
              ],
        breathingTip: isVi
            ? 'Thở mạnh ra khi đẩy tạ qua đầu - Hít sâu vào khi hạ tạ về ngang tai.'
            : 'Exhale powerfully on the overhead press - Inhale deeply as you lower dumbbells.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFF007AFF),
        isDumbbell: true,
      );
    }
    // Dumbbell 3: Bent-Over Row
    else if (lower.contains('row') || lower.contains('kéo tạ') || lower.contains('thon lưng') || lower.contains('lưng xô')) {
      return ExerciseGuideData(
        title: isVi ? 'Kéo tạ lưng xô' : 'Dumbbell Bent-Over Row',
        targetMuscles: isVi
            ? 'Cơ xô lưng, cơ trám, lưng giữa & thon gọn vùng nách'
            : 'Latissimus Dorsi, Rhomboids, Mid Back & Underarm Tone',
        steps: isVi
            ? [
                'Gập người ở khớp hông khoảng 45 độ, lưng thẳng tự nhiên, hai tay cầm tạ buông thẳng.',
                'Kéo tạ hướng về phía mạn sườn, hướng khuỷu tay ra sau và siết chặt cơ lưng.',
                'Dừng 1 nhịp ở đỉnh để co rút nhóm cơ xô rồi từ từ nhả tạ xuống.',
              ]
            : [
                'Hinge forward at hips at a 45-degree angle, flat back, arms hanging naturally.',
                'Drive elbows back toward your ribs, pulling dumbbells up and squeezing back muscles.',
                'Pause briefly at peak contraction, then lower dumbbells with control.',
              ],
        breathingTip: isVi
            ? 'Thở ra dứt khoát khi kéo tạ lên - Hít sâu vào khi duỗi tay hạ tạ.'
            : 'Exhale as you pull weights toward hips - Inhale smoothly as you lower down.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFF30D158),
        isDumbbell: true,
      );
    }
    // Dumbbell 4: Bicep Curls
    else if (lower.contains('curl') || lower.contains('cuốn tạ') || lower.contains('tay trước') || lower.contains('thon bắp tay')) {
      return ExerciseGuideData(
        title: isVi ? 'Cuốn tạ tay trước' : 'Dumbbell Bicep Curls',
        targetMuscles: isVi
            ? 'Cơ bắp tay trước (Biceps) & cẳng tay'
            : 'Biceps Brachii, Brachialis & Forearms',
        steps: isVi
            ? [
                'Đứng thẳng, hai tay cầm tạ xuôi theo thân, lòng bàn tay hướng về phía trước.',
                'Giữ khuỷu tay cố định sát sườn, cuộn tạ lên hướng về phía vai và siết căng bắp tay.',
                'Giữ 1 giây ở điểm cao nhất rồi từ từ hạ tạ xuống trong 2 giây.',
              ]
            : [
                'Stand tall with dumbbells at sides, palms facing forward.',
                'Keep elbows tucked near ribs, curl dumbbells upward toward shoulders squeezing biceps.',
                'Hold for 1 second at top contraction, then lower slowly over 2 seconds.',
              ],
        breathingTip: isVi
            ? 'Thở ra khi cuộn tạ lên - Hít vào khi hạ tạ duỗi thẳng tay.'
            : 'Exhale as you curl dumbbells up - Inhale as you lower arms down.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFFF9500),
        isDumbbell: true,
      );
    }
    // Dumbbell 5: Lateral Raises
    else if (lower.contains('lateral') || lower.contains('dang tạ') || lower.contains('vai thon')) {
      return ExerciseGuideData(
        title: isVi ? 'Dang tạ ngang' : 'Dumbbell Lateral Raises',
        targetMuscles: isVi
            ? 'Cơ vai giữa (tạo bờ vai thanh thoát, tôn dáng chuẩn)'
            : 'Lateral Deltoids (Shoulder Sculpting & Toning)',
        steps: isVi
            ? [
                'Đứng thẳng, hơi khom người về trước một chút, cầm tạ đặt trước đùi.',
                'Nâng hai cánh tay dang sang hai bên cho tới khi tạ ngang tầm vai.',
                'Giữ khuỷu tay hơi cong nhẹ, hạ tạ từ từ xuống vị trí ban đầu.',
              ]
            : [
                'Stand tall with slight forward torso tilt, dumbbells resting in front of thighs.',
                'Raise arms out to sides until dumbbells reach shoulder level with slight elbow bend.',
                'Lower weights down with slow tempo back to thighs.',
              ],
        breathingTip: isVi
            ? 'Thở ra khi dang tạ sang hai bên - Hít vào khi hạ tạ xuống.'
            : 'Exhale as you raise arms laterally - Inhale as you lower down.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFBF5AF2),
        isDumbbell: true,
      );
    }
    // Dumbbell 6: Romanian Deadlift (RDL)
    else if (lower.contains('rdl') || lower.contains('deadlift')) {
      return ExerciseGuideData(
        title: isVi ? 'Deadlift tạ đơn (RDL)' : 'Dumbbell Romanian Deadlift (RDL)',
        targetMuscles: isVi
            ? 'Cơ đùi sau, cơ mông lớn & nhóm cơ thắt lưng dưới'
            : 'Hamstrings, Gluteus Maximus & Spinal Erectors',
        steps: isVi
            ? [
                'Đứng thẳng hai chân rộng bằng hông, hai tay cầm tạ trước đùi.',
                'Đẩy hông ra phía sau, giữ lưng thẳng tắp, trượt tạ dọc theo ống đồng xuống qua gối.',
                'Khi cảm nhận cơ đùi sau căng hết cỡ, siết chặt cơ mông và đẩy hông về phía trước đứng thẳng lên.',
              ]
            : [
                'Stand feet hip-width apart holding dumbbells in front of thighs.',
                'Push hips backward with flat back, sliding dumbbells down shins just past knees.',
                'Feel hamstrings stretch, then drive hips forward and squeeze glutes to stand.',
              ],
        breathingTip: isVi
            ? 'Hít sâu siết chặt cơ bụng khi gập hông - Thở dứt khoát khi đứng thẳng siết mông.'
            : 'Inhale and brace core as you hinge back - Exhale powerfully as you stand tall.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFFF5252),
        isDumbbell: true,
      );
    }
    // Dumbbell 7: Sumo Squat / Goblet Squat with Dumbbell
    else if (lower.contains('sumo') || (lower.contains('squat') && (lower.contains('ôm tạ') || lower.contains('goblet') || lower.contains('tạ')))) {
      return ExerciseGuideData(
        title: isVi ? 'Squat tạ đơn (Sumo / Goblet)' : 'Dumbbell Sumo / Goblet Squat',
        targetMuscles: isVi
            ? 'Cơ đùi trong, cơ mông & cơ đùi trước săn chắc'
            : 'Inner Thighs (Adductors), Glutes & Quadriceps',
        steps: isVi
            ? [
                'Đứng chân rộng hơn vai, mũi chân mở góc 45 độ, ôm tạ trước ngực hoặc cầm buông giữa hai chân.',
                'Mở rộng đầu gối theo hướng mũi chân, hạ thấp hông sâu xuống mà vẫn giữ thẳng lưng.',
                'Đạp mạnh gót chân đẩy người đứng lên và siết chặt vòng 3 ở đỉnh chuyển động.',
              ]
            : [
                'Stand feet wider than shoulders, toes angled out 45 degrees, holding dumbbell at chest or center.',
                'Track knees over toes, sinking hips deep into squat while keeping chest proud.',
                'Drive through heels to stand upright and lock in glute squeeze at the top.',
              ],
        breathingTip: isVi
            ? 'Hít sâu vào khi hạ mông xuống thấp - Thở mạnh ra khi đạp gót đứng lên.'
            : 'Inhale on the deep squat descent - Exhale forcefully as you drive back up.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFF34C759),
        isDumbbell: true,
      );
    }
    // Dumbbell 8: Overhead Triceps Extension
    else if (lower.contains('triceps') || lower.contains('sau đầu') || lower.contains('tay sau')) {
      return ExerciseGuideData(
        title: isVi ? 'Đưa tạ sau đầu bắp tay sau' : 'Overhead Triceps Extension',
        targetMuscles: isVi
            ? 'Cơ tay sau (Triceps) - Loại bỏ mỡ bắp tay nhão'
            : 'Triceps Brachii (Arm Toning & Firming)',
        steps: isVi
            ? [
                'Đứng hoặc ngồi thẳng, dùng cả hai tay cầm chắc một quả tạ đưa thẳng lên qua đầu.',
                'Giữ bắp tay cố định gần tai, chỉ gập khớp khuỷu tay để hạ tạ xuống phía sau đầu.',
                'Dùng lực bắp tay sau duỗi thẳng cẳng tay đưa tạ trở lại vị trí ban đầu.',
              ]
            : [
                'Stand or sit upright, holding one dumbbell with both hands extended directly overhead.',
                'Keep upper arms locked near ears, bending only elbows to lower dumbbell behind head.',
                'Contract triceps to extend arms straight back up to starting position.',
              ],
        breathingTip: isVi
            ? 'Hít vào khi hạ tạ sau đầu - Thở ra mạnh mẽ khi duỗi thẳng tay lên.'
            : 'Inhale as dumbbell lowers behind head - Exhale as you extend arms overhead.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFFF9500),
        isDumbbell: true,
      );
    }
    // Dumbbell 9: Dumbbell Glute Bridge / Hip Thrust
    else if (lower.contains('hip thrust') || (lower.contains('cầu mông') && lower.contains('tạ'))) {
      return ExerciseGuideData(
        title: isVi ? 'Cầu mông đặt tạ đơn' : 'Dumbbell Hip Thrust / Glute Bridge',
        targetMuscles: isVi
            ? 'Kích hoạt tối đa cơ mông, làm cong mông & đùi sau'
            : 'Gluteus Maximus Hypertrophy, Hips & Hamstrings',
        steps: isVi
            ? [
                'Nằm ngửa gập gối, đặt quả tạ an toàn lên vùng xương chậu/hông và giữ nhẹ bằng hai tay.',
                'Đạp mạnh gót chân đẩy hông lên cao hết biên độ, tạo đường thẳng từ gối tới vai.',
                'Siết chặt mông hết cỡ ở vị trí cao nhất trong 2 giây rồi từ từ hạ xuống.',
              ]
            : [
                'Lie flat with knees bent, holding dumbbell securely across pelvis/hip crease.',
                'Drive forcefully through heels to thrust hips upward until knees, hips, and shoulders align.',
                'Squeeze glutes with maximum tension for 2 seconds at the peak before lowering.',
              ],
        breathingTip: isVi
            ? 'Thở mạnh ra khi đẩy hông lên - Hít vào khi hạ mông về sàn.'
            : 'Exhale powerfully on hip thrust - Inhale smoothly as hips descend.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFFF2D55),
        isDumbbell: true,
      );
    }
    // 1. Pull-ups
    else if (lower.contains('pull') || lower.contains('xà đơn')) {
      return ExerciseGuideData(
        title: isVi ? 'Hít xà đơn' : 'Pull-ups',
        targetMuscles: isVi
            ? 'Cơ xô lưng, bắp tay trước, lưng trên & cẳng tay'
            : 'Lats (Back), Biceps, Upper Back & Forearms',
        steps: isVi
            ? [
                'Nắm thanh xà rộng hơn vai một chút, lòng bàn tay hướng ra ngoài.',
                'Gồng cơ bụng, kéo bả vai xuống và ra sau, kéo ngực hướng lên xà.',
                'Đưa cằm vượt qua xà, dừng một nhịp rồi hạ người xuống có kiểm soát.',
              ]
            : [
                'Grip the pull-up bar slightly wider than shoulder-width with palms facing away.',
                'Engage your core, pull your shoulder blades down and back, and pull your chest toward the bar.',
                'Bring your chin above the bar, pause briefly, then lower yourself down with full control.',
              ],
        breathingTip: isVi
            ? 'Thở mạnh ra khi kéo người lên - Hít sâu vào khi hạ người xuống.'
            : 'Exhale powerfully as you pull yourself up - Inhale smoothly as you lower down.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFF007AFF),
      );
    }
    // 2. Diamond Push-ups
    else if (lower.contains('diamond') || lower.contains('kim cương')) {
      return ExerciseGuideData(
        title: isVi ? 'Hít đất kim cương' : 'Diamond Push-ups',
        targetMuscles: isVi
            ? 'Cơ tay sau, ngực trong & cơ vai trước'
            : 'Triceps, Inner Chest & Anterior Deltoids',
        steps: isVi
            ? [
                'Đặt hai bàn tay sát nhau dưới ngực, ngón cái và ngón trỏ chạm nhau tạo hình kim cương.',
                'Hạ ngực sát về phía hai bàn tay trong khi giữ khuỷu tay khép sát mạn sườn.',
                'Dùng lực tay sau và ngực đẩy mạnh người về vị trí ban đầu.',
              ]
            : [
                'Place your hands close together under your chest with thumbs and index fingers touching to form a diamond.',
                'Lower your chest toward your hands while keeping your elbows tucked close to your ribs.',
                'Push firmly through your triceps and chest to return to the starting position.',
              ],
        breathingTip: isVi
            ? 'Hít sâu vào khi hạ thấp ngực - Thở dứt khoát ra khi đẩy người lên.'
            : 'Inhale deeply as you lower your chest - Exhale sharply as you press up.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFFF2D55),
      );
    }
    // 3. Regular Push-ups
    else if (lower.contains('push') || lower.contains('hít đất')) {
      return ExerciseGuideData(
        title: isVi ? 'Hít đất' : 'Push-ups',
        targetMuscles: isVi
            ? 'Cơ ngực, tay sau, vai & cơ bụng (Core)'
            : 'Chest, Triceps, Shoulders & Core',
        steps: isVi
            ? [
                'Đặt tay rộng hơn vai một chút, toàn thân tạo thành một đường thẳng từ đầu đến gót chân.',
                'Siết cơ bụng và mông, từ từ hạ ngực xuống cách mặt đất khoảng 3-5 cm.',
                'Đẩy mạnh lòng bàn tay xuống sàn để nâng toàn bộ cơ thể trở lại vị trí ban đầu.',
              ]
            : [
                'Place hands slightly wider than shoulder-width, keeping body in a straight line from head to heels.',
                'Brace your core and glutes, slowly lowering chest until it is about 3-5 cm above the ground.',
                'Press forcefully through palms to push your body back to the top position.',
              ],
        breathingTip: isVi
            ? 'Hít sâu bằng mũi khi hạ người - Thở mạnh bằng miệng khi đẩy người lên.'
            : 'Inhale through your nose on the way down - Exhale forcefully through your mouth on the way up.',
        mainIcon: Icons.fitness_center_rounded,
        themeColor: const Color(0xFFE50914),
      );
    }
    // 4. Burpees
    else if (lower.contains('burpee')) {
      return ExerciseGuideData(
        title: isVi ? 'Nhảy Burpees đốt mỡ' : 'Burpees (Full Body Fat Burn)',
        targetMuscles: isVi
            ? 'Ngực, đùi trước, mông, cơ bụng & tim mạch'
            : 'Chest, Quads, Glutes, Core & Cardiovascular',
        steps: isVi
            ? [
                'Đứng thẳng, hạ người vào tư thế squat rồi đặt hai tay chạm sàn phía trước.',
                'Bật hai chân ra sau về tư thế plank cao và thực hiện một nhịp hít đất nhẹ nhàng.',
                'Bật thu chân lại tư thế squat rồi bật nhảy mạnh lên cao, vỗ hai tay qua đầu.',
              ]
            : [
                'Start standing straight, drop into a squat and place both hands on the floor in front of you.',
                'Jump feet back into a high plank position and perform one smooth push-up.',
                'Jump feet back toward hands into squat stance and explode upward, clapping hands overhead.',
              ],
        breathingTip: isVi
            ? 'Duy trì nhịp thở đều đặn và nhịp nhàng qua từng lần bật nhảy và hít đất.'
            : 'Maintain a steady, rhythmic breathing pattern through each jump and push-up.',
        mainIcon: Icons.flash_on_rounded,
        themeColor: const Color(0xFFFF3B30),
      );
    }
    // 5. Mountain Climbers
    else if (lower.contains('mountain') || lower.contains('leo núi')) {
      return ExerciseGuideData(
        title: isVi ? 'Leo núi Mountain Climbers' : 'Mountain Climbers',
        targetMuscles: isVi
            ? 'Cơ bụng dưới, cơ liên sườn, vai & cơ gập hông'
            : 'Lower Abs, Core, Shoulders & Hip Flexors',
        steps: isVi
            ? [
                'Bắt đầu ở tư thế plank cao với cổ tay thẳng ngay dưới vai.',
                'Kéo gối phải về sát ngực nhất có thể nhưng vẫn giữ lưng thẳng không bị gù.',
                'Đổi chân liên tục như đang chạy nước rút trên sàn, giữ hông ổn định không lắc lư.',
              ]
            : [
                'Begin in a high plank position with wrists aligned directly under shoulders.',
                'Drive your right knee toward your chest as close as possible without rounding your back.',
                'Quickly switch legs in an alternating sprinting motion while keeping hips level.',
              ],
        breathingTip: isVi
            ? 'Hít thở đều đặn theo nhịp luân phiên của từng bước chạy gối.'
            : 'Breathe rhythmically and continuously with each alternating knee drive.',
        mainIcon: Icons.directions_run_rounded,
        themeColor: const Color(0xFFFF9500),
      );
    }
    // 6. Russian Twists
    else if (lower.contains('russian') || lower.contains('vặn bụng')) {
      return ExerciseGuideData(
        title: isVi ? 'Vặn bụng Russian Twists' : 'Russian Twists',
        targetMuscles: isVi
            ? 'Cơ liên sườn, cơ bụng chéo & lưng dưới'
            : 'Obliques, Rotational Core & Lower Back',
        steps: isVi
            ? [
                'Ngồi gập gối trên sàn, ngả người ra sau một góc khoảng 45 độ.',
                'Nhấc nhẹ hai bàn chân lên khỏi sàn để siết chặt toàn bộ thành bụng.',
                'Xoay thân trên từ trái qua phải, chạm nhẹ hai tay sang hai bên hông.',
              ]
            : [
                'Sit on the floor with knees bent and lean your torso back at a 45-degree angle.',
                'Elevate your feet slightly off the ground to fully activate your abdominal wall.',
                'Rotate your torso from left to right, tapping hands lightly beside each hip.',
              ],
        breathingTip: isVi
            ? 'Thở ra khi xoay thân sang mỗi bên - Hít vào khi chuyển qua điểm giữa.'
            : 'Exhale as you rotate to each side - Inhale through the center transition.',
        mainIcon: Icons.rotate_right_rounded,
        themeColor: const Color(0xFFFFCC00),
      );
    }
    // 7. Bicycle Crunches
    else if (lower.contains('bicycle') || lower.contains('đạp xe')) {
      return ExerciseGuideData(
        title: isVi ? 'Đạp xe gập bụng Bicycle' : 'Bicycle Crunches',
        targetMuscles: isVi
            ? 'Cơ bụng 6 múi, cơ bụng dưới & liên sườn'
            : 'Six-pack Abs, Lower Core & Obliques',
        steps: isVi
            ? [
                'Nằm ngửa, đặt hai tay nhẹ sau đầu, nâng hai đầu gối tạo góc 90 độ.',
                'Xoay vai trái đưa khuỷu tay chạm gối phải, đồng thời duỗi thẳng chân trái.',
                'Luân phiên đổi bên nhịp nhàng liên tục như đang đạp xe đạp.',
              ]
            : [
                'Lie on your back with hands lightly behind head, elevating knees to a 90-degree angle.',
                'Rotate left shoulder to bring left elbow to meet right knee while extending left leg straight.',
                'Alternate sides smoothly in a continuous pedaling motion.',
              ],
        breathingTip: isVi
            ? 'Thở dứt khoát mỗi khi khuỷu tay chạm gối - Hít vào khi đổi bên.'
            : 'Exhale sharply with each elbow-to-knee contact - Inhale as you switch sides.',
        mainIcon: Icons.pedal_bike_rounded,
        themeColor: const Color(0xFFFF9500),
      );
    }
    // 8. Crunches
    else if (lower.contains('crunch') || lower.contains('gập bụng')) {
      return ExerciseGuideData(
        title: isVi ? 'Gập bụng' : 'Crunches',
        targetMuscles: isVi
            ? 'Cơ bụng trên, cơ bụng sâu & liên sườn'
            : 'Upper Abs, Deep Core & Obliques',
        steps: isVi
            ? [
                'Nằm ngửa gập gối, hai bàn chân đặt vững trên sàn rộng bằng hông.',
                'Bắt chéo tay trước ngực hoặc đặt nhẹ các ngón tay sau tai, không kéo cổ.',
                'Siết cơ bụng nâng bả vai lên cách sàn 5-8 cm, dừng một nhịp rồi hạ chậm xuống.',
              ]
            : [
                'Lie on back with knees bent and feet flat on the floor about hip-width apart.',
                'Cross arms over chest or place fingers lightly behind ears without pulling your neck.',
                'Contract abs to lift shoulder blades 5-8 cm off the floor, pause, and lower back down slowly.',
              ],
        breathingTip: isVi
            ? 'Thở mạnh ra ở đỉnh điểm gập bụng - Hít sâu vào khi hạ vai xuống thảm.'
            : 'Exhale powerfully at the peak of the curl - Inhale as your shoulders return to the mat.',
        mainIcon: Icons.sports_gymnastics_rounded,
        themeColor: const Color(0xFFFF9500),
      );
    }
    // 9. Glute Bridges
    else if (lower.contains('bridge') || lower.contains('cầu mông')) {
      return ExerciseGuideData(
        title: isVi ? 'Cầu mông Glute Bridges' : 'Glute Bridges',
        targetMuscles: isVi
            ? 'Cơ mông lớn (Glutes), đùi sau & lưng dưới'
            : 'Gluteus Maximus, Hamstrings & Lower Back',
        steps: isVi
            ? [
                'Nằm ngửa, gập gối và đặt bàn chân phẳng trên sàn cách mông một khoảng vừa phải.',
                'Dồn lực vào gót chân nâng hông lên cao cho đến khi gối, hông và vai tạo đường thẳng.',
                'Siết chặt cơ mông ở vị trí cao nhất trong 2 giây rồi từ từ hạ hông xuống.',
              ]
            : [
                'Lie flat on back with knees bent and feet planted flat hip-width apart near glutes.',
                'Drive through heels to lift hips upward until knees, hips, and shoulders form a straight line.',
                'Squeeze glutes hard at the peak for 2 seconds, then slowly descend back down.',
              ],
        breathingTip: isVi
            ? 'Thở ra khi đẩy hông lên cao - Hít vào khi hạ hông chạm sàn.'
            : 'Exhale as you drive hips toward the ceiling - Inhale as you lower hips to the floor.',
        mainIcon: Icons.airline_seat_legroom_extra_rounded,
        themeColor: const Color(0xFFFF2D55),
      );
    }
    // 10. Donkey Kicks
    else if (lower.contains('donkey') || lower.contains('đá mông')) {
      return ExerciseGuideData(
        title: isVi ? 'Đá mông Donkey Kicks' : 'Donkey Kicks',
        targetMuscles: isVi
            ? 'Cơ mông trên, làm tròn mông & đùi sau'
            : 'Upper Glutes, Glute Shaping & Hamstrings',
        steps: isVi
            ? [
                'Chống hai tay và đầu gối xuống sàn (tư thế bò), cổ tay dưới vai, gối dưới hông.',
                'Giữ đầu gối gập 90 độ, đá gót một chân thẳng lên hướng trần nhà.',
                'Siết cơ mông ở đỉnh mà không võng lưng, sau đó hạ chân xuống có kiểm soát.',
              ]
            : [
                'Position on all fours with wrists below shoulders and knees below hips.',
                'Keeping knee bent at 90 degrees, kick one heel upward toward the ceiling.',
                'Squeeze glute at top without arching back, then lower leg under control.',
              ],
        breathingTip: isVi
            ? 'Thở ra khi đá chân lên cao - Hít vào khi đưa gối về vị trí xuất phát.'
            : 'Exhale on the upward kick - Inhale as you return knee to starting position.',
        mainIcon: Icons.sports_kabaddi_rounded,
        themeColor: const Color(0xFFAF52DE),
      );
    }
    // 11. Lunges / Jumping Lunges / Reverse Lunges
    else if (lower.contains('lunge') || lower.contains('chùng chân')) {
      return ExerciseGuideData(
        title: isVi ? 'Chùng chân Lunges' : 'Lunges',
        targetMuscles: isVi
            ? 'Cơ tứ đầu đùi, cơ mông, bắp chuối & giữ thăng bằng'
            : 'Quads, Glutes, Calves & Core Balance',
        steps: isVi
            ? [
                'Đứng thẳng người hai chân chụm, bước một chân dài về phía trước hoặc phía sau.',
                'Hạ thân người xuống cho đến khi cả hai đầu gối đều gập khoảng 90 độ.',
                'Dồn lực vào gót chân trước để đẩy người trở lại tư thế đứng thẳng ban đầu.',
              ]
            : [
                'Stand tall with feet together, take a controlled step forward or backward.',
                'Lower your body until both knees are bent at roughly 90-degree angles.',
                'Push off the heel of your lead foot to return to the starting upright position.',
              ],
        breathingTip: isVi
            ? 'Hít vào khi hạ thấp thân người - Thở ra khi đẩy người đứng thẳng lên.'
            : 'Inhale as you lower down into the lunge - Exhale as you push back up to standing.',
        mainIcon: Icons.directions_walk_rounded,
        themeColor: const Color(0xFF34C759),
      );
    }
    // 12. Jumping Jacks
    else if (lower.contains('jumping') || lower.contains('nhảy')) {
      return ExerciseGuideData(
        title: isVi ? 'Nhảy Jumping Jacks' : 'Jumping Jacks',
        targetMuscles: isVi
            ? 'Toàn thân, bắp chân, cơ vai & sức bền tim mạch'
            : 'Full Body, Calves, Deltoids & Cardio Stamina',
        steps: isVi
            ? [
                'Đứng thẳng với hai chân khép sát, hai tay thả lỏng hai bên người.',
                'Bật nhảy tách hai chân rộng hơn vai đồng thời vung hai tay qua đầu chạm nhau.',
                'Bật thu chân và tay trở lại nhanh chóng, tiếp đất nhẹ nhàng bằng mũi chân.',
              ]
            : [
                'Stand upright with feet together and arms resting comfortably at your sides.',
                'Jump feet out past shoulder-width while raising arms overhead until hands touch.',
                'Quickly reverse motion, landing softly on balls of feet in a fluid rhythm.',
              ],
        breathingTip: isVi
            ? 'Hít thở nhịp nhàng tự nhiên, tiếp đất êm ái để bảo vệ khớp gối.'
            : 'Breathe naturally and steadily, landing softly to minimize impact on joints.',
        mainIcon: Icons.accessibility_rounded,
        themeColor: const Color(0xFF00C6FF),
      );
    }
    // 13. Plank
    else if (lower.contains('plank')) {
      return ExerciseGuideData(
        title: isVi ? 'Plank siết cơ bụng' : 'Plank',
        targetMuscles: isVi
            ? 'Cơ bụng sâu, cơ ngang bụng & cơ mông'
            : 'Core Abdominals, Transverse Abdominis & Glutes',
        steps: isVi
            ? [
                'Chống cẳng tay xuống sàn, khuỷu tay ngay dưới vai, mũi chân chống vững.',
                'Giữ toàn thân tạo thành một đường thẳng tắp từ đỉnh đầu đến gót chân, không chùng hông.',
                'Gồng chặt cơ bụng và siết cơ mông trong suốt thời gian giữ tư thế.',
              ]
            : [
                'Rest on forearms with elbows aligned directly under shoulders, toes planted on floor.',
                'Maintain a rigid straight line from crown of head to heels without sagging hips.',
                'Engage core and squeeze glutes firmly for the entire duration of the hold.',
              ],
        breathingTip: isVi
            ? 'Hít thở sâu bằng cơ hoành, đều đặn. Tuyệt đối không nín thở khi giữ plank.'
            : 'Take deep, controlled diaphragmatic breaths. Never hold your breath during the hold.',
        mainIcon: Icons.accessibility_new_rounded,
        themeColor: const Color(0xFF00C6FF),
      );
    }
    // 14. Squats
    else if (lower.contains('squat')) {
      return ExerciseGuideData(
        title: isVi ? 'Squat mông đùi' : 'Squats (Glutes & Legs)',
        targetMuscles: isVi
            ? 'Cơ đùi trước, cơ mông & gân kheo đùi sau'
            : 'Quadriceps, Gluteal Complex & Hamstrings',
        steps: isVi
            ? [
                'Đứng hai chân rộng bằng vai, các ngón chân hơi xoay nhẹ ra ngoài (khoảng 15 độ).',
                'Đẩy hông ra sau và gập gối, hạ thấp người như chuẩn bị ngồi xuống một chiếc ghế.',
                'Hạ đến khi đùi song song với mặt sàn, giữ ngực thẳng, sau đó đạp mạnh gót chân đứng lên.',
              ]
            : [
                'Stand with feet shoulder-width apart, toes pointing slightly outward (15 degrees).',
                'Hinge at hips and bend knees, sitting back as if reaching for an invisible chair.',
                'Reach thighs parallel to floor with chest upright, then push through heels to stand.',
              ],
        breathingTip: isVi
            ? 'Hít sâu vào khi hạ người xuống - Thở mạnh ra khi đạp gót đứng lên.'
            : 'Inhale deeply as you descend - Exhale powerfully as you push up to standing.',
        mainIcon: Icons.directions_run_rounded,
        themeColor: const Color(0xFF30D158),
      );
    }
    // 15. Yoga
    else if (lower.contains('yoga') || lower.contains('stretch') || lower.contains('giãn')) {
      return ExerciseGuideData(
        title: isVi ? 'Giãn cơ Yoga dẻo dai' : 'Yoga Flexibility Stretch',
        targetMuscles: isVi
            ? 'Cột sống, cơ gập hông, gân kheo & giải tỏa căng thẳng'
            : 'Spine, Hip Flexors, Hamstrings & Stress Relief',
        steps: isVi
            ? [
                'Ngồi thẳng lưng trên thảm hoặc vươn người trong tư thế rắn hổ mang nhẹ nhàng.',
                'Kéo dài cột sống, vươn các chi thư giãn từ từ mà không ép khớp quá mức.',
                'Thả lỏng toàn bộ cơ cổ, quai hàm và hai vai để máu huyết lưu thông tối đa.',
              ]
            : [
                'Adopt an upright seated pose or gentle upward cobra stretch on your yoga mat.',
                'Lengthen through the spine, extending limbs smoothly without forcing any joints.',
                'Release all tension from neck, jaw, and shoulders to optimize blood circulation.',
              ],
        breathingTip: isVi
            ? 'Hít vào 4 giây - Giữ hơi 2 giây - Thở ra nhẹ nhàng trong 6 giây.'
            : 'Inhale for 4 seconds - Hold for 2 seconds - Exhale slowly for 6 seconds.',
        mainIcon: Icons.self_improvement_rounded,
        themeColor: const Color(0xFFBF5AF2),
      );
    }

    return ExerciseGuideData(
      title: isVi ? 'Vận động thể chất' : 'Bodyweight Movement',
      targetMuscles: isVi
          ? 'Tăng cường sức bền toàn thân & đốt cháy năng lượng'
          : 'Full Body Conditioning & Calorie Burn',
      steps: isVi
          ? [
              'Khởi động kỹ các khớp cổ tay, cổ chân, khớp gối trước khi tập.',
              'Tập trung vào đúng kỹ thuật và giữ nhịp điệu chuyển động đều đặn.',
              'Uống từng ngụm nước nhỏ khi cần để bổ sung đủ nước và thể lực.',
            ]
          : [
              'Warm up joints thoroughly before initiating the movement.',
              'Focus on controlled form and continuous tempo throughout each repetition.',
              'Sip water as needed to maintain hydration and performance.',
            ],
      breathingTip: isVi
          ? 'Hít thở đều đặn và nhịp nhàng theo sức vận động của cơ thể.'
          : 'Breathe evenly in cadence with the physical exertion.',
      mainIcon: Icons.fitness_center_rounded,
      themeColor: AppTheme.primaryColor,
    );
  }
}

/// Widget hoạt ảnh chuyển động mô phỏng động tác giải phẫu 100% Offline mượt mà
class ExercisePoseAnimator extends StatefulWidget {
  final String exerciseTitle;
  final bool isPlaying;
  final double height;
  final bool isMale;

  const ExercisePoseAnimator({
    super.key,
    required this.exerciseTitle,
    this.isPlaying = true,
    this.height = 150,
    this.isMale = true,
  });

  @override
  State<ExercisePoseAnimator> createState() => _ExercisePoseAnimatorState();
}

class _ExercisePoseAnimatorState extends State<ExercisePoseAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ExercisePoseAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeColor = widget.isMale
        ? const Color(0xFF00F0FF)
        : const Color(0xFFFF2E93);
    final exType = AnatomyKinematicPainter.resolveExerciseType(widget.exerciseTitle);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final smoothPhase = AnatomyKinematicPainter.computeBiomechanicalPhase(
          _controller.value,
          exType,
        );

        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0C101A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activeThemeColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: activeThemeColor.withValues(alpha: 0.10),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Kinematic Human Anatomy Model Canvas
                Positioned.fill(
                  child: CustomPaint(
                    painter: AnatomyKinematicPainter(
                      progress: smoothPhase,
                      exerciseTitle: widget.exerciseTitle,
                      isMale: widget.isMale,
                    ),
                  ),
                ),
                // Gender badge in top left
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: activeThemeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: activeThemeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isMale ? Icons.male_rounded : Icons.female_rounded,
                          size: 11,
                          color: activeThemeColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.isMale ? 'Mô hình Nam ♂' : 'Mô hình Nữ ♀',
                          style: TextStyle(
                            color: activeThemeColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
