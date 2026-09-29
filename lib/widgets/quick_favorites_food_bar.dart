import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/favorite_food.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils/app_haptics.dart';
import 'app_ui_components.dart';

class QuickFavoritesFoodBar extends StatefulWidget {
  final VoidCallback? onFoodAdded;

  const QuickFavoritesFoodBar({super.key, this.onFoodAdded});

  @override
  State<QuickFavoritesFoodBar> createState() => _QuickFavoritesFoodBarState();
}

class _QuickFavoritesFoodBarState extends State<QuickFavoritesFoodBar> {
  List<FavoriteFood> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final list = await NutritionRepository.instance.getFavoriteFoods();
    if (mounted) {
      setState(() {
        _favorites = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _logFavorite(FavoriteFood fav, String mealType) async {
    AppHaptics.light();
    final entry = FoodLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: fav.name,
      calories: fav.calories,
      protein: fav.protein,
      carbs: fav.carbs,
      fat: fav.fat,
      mealType: mealType,
      imagePath: fav.imagePath,
      timestamp: DateTime.now(),
    );

    await NutritionRepository.instance.saveFoodLog(entry);
    StorageService.notifyFoodChanged();
    widget.onFoodAdded?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00F0FF), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${fav.name} (+${fav.calories} kcal) đã được thêm vào $mealType!',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1F2C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSelectMealDialog(FavoriteFood fav) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF131722),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedRestaurant01,
                    color: Color(0xFF00F0FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fav.name,
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${fav.calories} kcal • P: ${fav.protein}g C: ${fav.carbs}g F: ${fav.fat}g',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Chọn bữa ăn:',
              style: AppTheme.font(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMealOption(ctx, fav, 'Breakfast', '🍳 Sáng', const Color(0xFFFF9E00)),
                const SizedBox(width: 8),
                _buildMealOption(ctx, fav, 'Lunch', '🍚 Trưa', const Color(0xFF34C759)),
                const SizedBox(width: 8),
                _buildMealOption(ctx, fav, 'Dinner', '🍽️ Tối', const Color(0xFFAF52DE)),
                const SizedBox(width: 8),
                _buildMealOption(ctx, fav, 'Snack', '🍎 Phụ', const Color(0xFF00F0FF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealOption(
    BuildContext ctx,
    FavoriteFood fav,
    String mealType,
    String label,
    Color color,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pop(ctx);
          _logFavorite(fav, mealType);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCustomFavoriteDialog() {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final pCtrl = TextEditingController(text: '0');
    final cCtrl = TextEditingController(text: '0');
    final fCtrl = TextEditingController(text: '0');
    final sizeCtrl = TextEditingController(text: '1 phần');

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF131722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thêm Món Quen Thuộc',
                      style: AppTheme.font(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tên món ăn (vd: Phở bò, Yến mạch)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: calCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Calo (kcal)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sizeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Khẩu phần (vd: 1 tô)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Protein (g)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: cCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Carbs (g)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Fat (g)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final cal = int.tryParse(calCtrl.text.trim()) ?? 0;
                      if (name.isEmpty || cal <= 0) return;

                      final fav = FavoriteFood(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        calories: cal,
                        protein: int.tryParse(pCtrl.text.trim()) ?? 0,
                        carbs: int.tryParse(cCtrl.text.trim()) ?? 0,
                        fat: int.tryParse(fCtrl.text.trim()) ?? 0,
                        servingSize: sizeCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await NutritionRepository.instance.addFavoriteFood(fav);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      _loadFavorites();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Lưu vào Món Ưa Thích', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 48);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  color: Color(0xFFFF2A6D),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Món Ăn Quen Thuộc',
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: _showAddCustomFavoriteDialog,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Color(0xFF00F0FF), size: 16),
                    const SizedBox(width: 2),
                    Text(
                      'Thêm món',
                      style: AppTheme.font(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00F0FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_favorites.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, color: Colors.white38, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chưa có món yêu thích. Bấm biểu tượng ❤️ ở món ăn hoặc bấm "+ Thêm món" để lưu nhanh!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favorites.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final fav = _favorites[index];
                return InkWell(
                  onTap: () => _showSelectMealDialog(fav),
                  onLongPress: () async {
                    AppHaptics.medium();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1F2C),
                        title: const Text('Xóa khỏi ưa thích?', style: TextStyle(color: Colors.white, fontSize: 16)),
                        content: Text('Bạn có chắc muốn xóa "${fav.name}" khỏi danh mục ưa thích?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await NutritionRepository.instance.deleteFavoriteFood(fav.id);
                      _loadFavorites();
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151928),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.bolt, color: Color(0xFF00F0FF), size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fav.name,
                              style: AppTheme.font(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+${fav.calories} kcal • ${fav.protein}g P',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00F0FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
