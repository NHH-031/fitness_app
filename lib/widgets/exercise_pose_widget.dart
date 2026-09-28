import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/locale_service.dart';

class ExerciseGuideData {
  final String title;
  final String targetMuscles;
  final List<String> steps;
  final String breathingTip;
  final IconData mainIcon;
  final Color themeColor;

  const ExerciseGuideData({
    required this.title,
    required this.targetMuscles,
    required this.steps,
    required this.breathingTip,
    required this.mainIcon,
    required this.themeColor,
  });

  static ExerciseGuideData getForExercise(String title) {
    final lower = title.toLowerCase();
    final isVi = LocaleService.isVietnamese;

    // 1. Pull-ups
    if (lower.contains('pull') || lower.contains('xà đơn')) {
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

/// Widget hoạt ảnh chuyển động mô phỏng động tác 100% Offline mượt mà
class ExercisePoseAnimator extends StatefulWidget {
  final String exerciseTitle;
  final bool isPlaying;
  final double height;

  const ExercisePoseAnimator({
    super.key,
    required this.exerciseTitle,
    this.isPlaying = true,
    this.height = 150,
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
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ExercisePoseAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
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
    final guide = ExerciseGuideData.getForExercise(widget.exerciseTitle);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: guide.themeColor.withValues(alpha: 0.3)),
          ),
          child: CustomPaint(
            painter: _PosePainter(
              progress: _controller.value,
              exerciseTitle: widget.exerciseTitle,
              themeColor: guide.themeColor,
            ),
          ),
        );
      },
    );
  }
}

class _PosePainter extends CustomPainter {
  final double progress;
  final String exerciseTitle;
  final Color themeColor;

  _PosePainter({
    required this.progress,
    required this.exerciseTitle,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final lower = exerciseTitle.toLowerCase();

    // Sàn nhà / Nền đỡ
    final floorPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.8),
      Offset(size.width * 0.88, size.height * 0.8),
      floorPaint,
    );

    // Vầng hào quang chuyển động
    final glowPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.12 + 0.15 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 45 + 10 * progress, glowPaint);

    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final limbPaint = Paint()
      ..color = themeColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (lower.contains('pull') || lower.contains('xà đơn')) {
      _drawPullUp(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('hít đất') || lower.contains('push')) {
      _drawPushUp(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('burpee')) {
      _drawBurpee(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('mountain') || lower.contains('leo núi')) {
      _drawMountainClimber(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('cầu mông') || lower.contains('bridge')) {
      _drawGluteBridge(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('đá mông') || lower.contains('donkey')) {
      _drawDonkeyKick(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('chùng chân') || lower.contains('lunge')) {
      _drawLunge(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('jumping') || lower.contains('nhảy')) {
      _drawJumpingJack(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('gập bụng') || lower.contains('crunch') || lower.contains('russian') || lower.contains('vặn')) {
      _drawCrunch(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('plank')) {
      _drawPlank(canvas, size, limbPaint, jointPaint);
    } else if (lower.contains('squat')) {
      _drawSquat(canvas, size, limbPaint, jointPaint);
    } else {
      _drawYoga(canvas, size, limbPaint, jointPaint);
    }
  }

  void _drawPullUp(Canvas canvas, Size size, Paint limb, Paint joint) {
    final barY = size.height * 0.22;
    // Thanh xà đơn phía trên
    final barPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.2, barY),
      Offset(size.width * 0.8, barY),
      barPaint,
    );

    // progress: 0.0 -> buông thẳng tay (hanging); 1.0 -> kéo cằm vượt xà (pull-up peak)
    final pullProgress = progress;
    final hangY = size.height * 0.52;
    final chinUpY = size.height * 0.30;
    final shoulderY = hangY - (hangY - chinUpY) * pullProgress;
    final headY = shoulderY - 14;

    final centerX = size.width * 0.5;
    final head = Offset(centerX, headY);
    final shoulder = Offset(centerX, shoulderY);

    // 2 Bàn tay bám xà
    final leftHand = Offset(centerX - 28, barY);
    final rightHand = Offset(centerX + 28, barY);

    // 2 Khuỷu tay
    final elbowY = (shoulderY + barY) / 2 + (1.0 - pullProgress) * 10;
    final leftElbow = Offset(centerX - 24 - (pullProgress * 10), elbowY);
    final rightElbow = Offset(centerX + 24 + (pullProgress * 10), elbowY);

    // Vẽ cánh tay
    canvas.drawLine(leftHand, leftElbow, limb);
    canvas.drawLine(leftElbow, shoulder, limb);
    canvas.drawLine(rightHand, rightElbow, limb);
    canvas.drawLine(rightElbow, shoulder, limb);

    // Thân trên
    final hipY = shoulderY + 28;
    final hip = Offset(centerX, hipY);
    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);

    // Chân hơi gập gối tự nhiên
    final kneeY = hipY + 22;
    final footY = kneeY + 16;
    final leftKnee = Offset(centerX - 8, kneeY);
    final rightKnee = Offset(centerX + 8, kneeY);
    final leftFoot = Offset(centerX - 12, footY);
    final rightFoot = Offset(centerX + 12, footY);

    canvas.drawLine(hip, leftKnee, limb);
    canvas.drawLine(leftKnee, leftFoot, limb);
    canvas.drawLine(hip, rightKnee, limb);
    canvas.drawLine(rightKnee, rightFoot, limb);

    // Khớp & Đầu
    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(leftHand, 4, joint);
    canvas.drawCircle(rightHand, 4, joint);
    canvas.drawCircle(leftElbow, 3, joint);
    canvas.drawCircle(rightElbow, 3, joint);
    canvas.drawCircle(leftKnee, 3, joint);
    canvas.drawCircle(rightKnee, 3, joint);
  }

  void _drawPushUp(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final bodyLift = (1.0 - progress) * 26.0;

    final hand = Offset(size.width * 0.36, floorY);
    final feet = Offset(size.width * 0.75, floorY - 6);
    final shoulder = Offset(size.width * 0.36, floorY - 22 - bodyLift);
    final head = Offset(size.width * 0.27, floorY - 26 - bodyLift);
    final hip = Offset(size.width * 0.58, floorY - 14 - (bodyLift * 0.7));

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, feet, limb);

    final elbow = Offset(size.width * 0.42, (shoulder.dy + hand.dy) / 2 + (1.0 - progress) * 12);
    canvas.drawLine(shoulder, elbow, limb);
    canvas.drawLine(elbow, hand, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(elbow, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(hand, 4, joint);
    canvas.drawCircle(feet, 4, joint);
  }

  void _drawCrunch(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final curl = progress * 24.0;

    final hip = Offset(size.width * 0.42, floorY - 8);
    final knee = Offset(size.width * 0.58, floorY - 38);
    final feet = Offset(size.width * 0.68, floorY);

    final shoulder = Offset(size.width * 0.30 - (curl * 0.3), floorY - 10 - curl);
    final head = Offset(size.width * 0.22 - (curl * 0.4), floorY - 16 - curl * 1.3);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, knee, limb);
    canvas.drawLine(knee, feet, limb);

    final hand = Offset(head.dx + 4, head.dy);
    canvas.drawLine(shoulder, hand, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(knee, 4, joint);
    canvas.drawCircle(feet, 4, joint);
  }

  void _drawPlank(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final breathe = math.sin(progress * math.pi) * 4.0;

    final elbow = Offset(size.width * 0.32, floorY);
    final hand = Offset(size.width * 0.26, floorY);
    final feet = Offset(size.width * 0.74, floorY - 6);

    final shoulder = Offset(size.width * 0.32, floorY - 24 + breathe);
    final head = Offset(size.width * 0.24, floorY - 26 + breathe);
    final hip = Offset(size.width * 0.53, floorY - 16 + breathe);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, feet, limb);
    canvas.drawLine(shoulder, elbow, limb);
    canvas.drawLine(elbow, hand, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(elbow, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(feet, 4, joint);
  }

  void _drawSquat(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final squatDepth = progress * 28.0;

    final feet = Offset(size.width * 0.50, floorY);
    final knee = Offset(size.width * 0.58, floorY - 32 + (squatDepth * 0.4));
    final hip = Offset(size.width * 0.42 - (progress * 10), floorY - 58 + squatDepth);
    final shoulder = Offset(size.width * 0.47, hip.dy - 30);
    final head = Offset(size.width * 0.48, shoulder.dy - 16);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, knee, limb);
    canvas.drawLine(knee, feet, limb);

    final hand = Offset(size.width * 0.65, shoulder.dy + 8);
    canvas.drawLine(shoulder, hand, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(knee, 4, joint);
    canvas.drawCircle(feet, 4, joint);
  }

  void _drawLunge(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final depth = progress * 22.0;

    final frontFoot = Offset(size.width * 0.64, floorY);
    final frontKnee = Offset(size.width * 0.64, floorY - 26 + (depth * 0.3));
    final backFoot = Offset(size.width * 0.32, floorY - 4);
    final backKnee = Offset(size.width * 0.40, floorY - 10 - (20 - depth));

    final hip = Offset(size.width * 0.48, floorY - 50 + depth);
    final shoulder = Offset(size.width * 0.48, hip.dy - 30);
    final head = Offset(size.width * 0.48, shoulder.dy - 16);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, frontKnee, limb);
    canvas.drawLine(frontKnee, frontFoot, limb);
    canvas.drawLine(hip, backKnee, limb);
    canvas.drawLine(backKnee, backFoot, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(frontKnee, 4, joint);
    canvas.drawCircle(backKnee, 4, joint);
  }

  void _drawGluteBridge(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final bridgeLift = progress * 30.0;

    final shoulder = Offset(size.width * 0.30, floorY - 8);
    final head = Offset(size.width * 0.22, floorY - 8);
    final feet = Offset(size.width * 0.68, floorY);
    final knee = Offset(size.width * 0.60, floorY - 36);
    final hip = Offset(size.width * 0.45, floorY - 12 - bridgeLift);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, knee, limb);
    canvas.drawLine(knee, feet, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(knee, 4, joint);
    canvas.drawCircle(feet, 4, joint);
  }

  void _drawDonkeyKick(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final kickHeight = progress * 24.0;

    final hand = Offset(size.width * 0.35, floorY);
    final shoulder = Offset(size.width * 0.35, floorY - 32);
    final head = Offset(size.width * 0.26, floorY - 32);
    final hip = Offset(size.width * 0.58, floorY - 32);

    final groundKnee = Offset(size.width * 0.58, floorY);
    final kickKnee = Offset(size.width * 0.68, floorY - 30 - (kickHeight * 0.4));
    final kickFoot = Offset(size.width * 0.75, floorY - 35 - kickHeight);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hand, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, groundKnee, limb);
    canvas.drawLine(hip, kickKnee, limb);
    canvas.drawLine(kickKnee, kickFoot, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(kickFoot, 4, joint);
  }

  void _drawMountainClimber(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final drive = progress * 24.0;

    final hand = Offset(size.width * 0.35, floorY);
    final shoulder = Offset(size.width * 0.35, floorY - 26);
    final head = Offset(size.width * 0.27, floorY - 28);
    final hip = Offset(size.width * 0.58, floorY - 20);

    final backFoot = Offset(size.width * 0.78, floorY - 4);
    final driveKnee = Offset(size.width * 0.46 + (drive * 0.2), floorY - 14);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hand, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, backFoot, limb);
    canvas.drawLine(hip, driveKnee, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(driveKnee, 4, joint);
  }

  void _drawBurpee(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    // progress: 0.0 (chống đẩy sát sàn) -> 1.0 (nhảy bật cao lên)
    final jumpHeight = progress * 35.0;

    final feet = Offset(size.width * 0.50, floorY - jumpHeight);
    final hip = Offset(size.width * 0.50, feet.dy - 35);
    final shoulder = Offset(size.width * 0.50, hip.dy - 30);
    final head = Offset(size.width * 0.50, shoulder.dy - 16);

    final handLeft = Offset(size.width * 0.36 - (progress * 8), shoulder.dy - 20);
    final handRight = Offset(size.width * 0.64 + (progress * 8), shoulder.dy - 20);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, feet, limb);
    canvas.drawLine(shoulder, handLeft, limb);
    canvas.drawLine(shoulder, handRight, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(feet, 4, joint);
  }

  void _drawJumpingJack(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final spread = progress * 20.0;

    final centerFoot = Offset(size.width * 0.50, floorY);
    final footLeft = Offset(centerFoot.dx - spread, floorY);
    final footRight = Offset(centerFoot.dx + spread, floorY);

    final hip = Offset(size.width * 0.50, floorY - 45);
    final shoulder = Offset(size.width * 0.50, floorY - 75);
    final head = Offset(size.width * 0.50, shoulder.dy - 16);

    final handLeft = Offset(size.width * 0.40 - spread, shoulder.dy - (progress * 25));
    final handRight = Offset(size.width * 0.60 + spread, shoulder.dy - (progress * 25));

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, footLeft, limb);
    canvas.drawLine(hip, footRight, limb);
    canvas.drawLine(shoulder, handLeft, limb);
    canvas.drawLine(shoulder, handRight, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
  }

  void _drawYoga(Canvas canvas, Size size, Paint limb, Paint joint) {
    final floorY = size.height * 0.78;
    final stretch = progress * 12.0;

    final hip = Offset(size.width * 0.45, floorY - 10);
    final feet = Offset(size.width * 0.55, floorY);
    final shoulder = Offset(size.width * 0.45, floorY - 55);
    final head = Offset(size.width * 0.45, shoulder.dy - 16);

    final leftHand = Offset(size.width * 0.32 - stretch, shoulder.dy - 20 - stretch);
    final rightHand = Offset(size.width * 0.58 + stretch, shoulder.dy - 20 - stretch);

    canvas.drawLine(head, shoulder, limb);
    canvas.drawLine(shoulder, hip, limb);
    canvas.drawLine(hip, feet, limb);
    canvas.drawLine(shoulder, leftHand, limb);
    canvas.drawLine(shoulder, rightHand, limb);

    canvas.drawCircle(head, 9, joint);
    canvas.drawCircle(shoulder, 4, joint);
    canvas.drawCircle(hip, 4, joint);
    canvas.drawCircle(leftHand, 4, joint);
    canvas.drawCircle(rightHand, 4, joint);
  }

  @override
  bool shouldRepaint(covariant _PosePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.exerciseTitle != exerciseTitle;
  }
}
