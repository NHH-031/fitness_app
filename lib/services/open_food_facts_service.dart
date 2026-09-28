import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model lưu thông tin sản phẩm quét được từ mã vạch
class ScannedFoodProduct {
  final String barcode;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String? servingSize;
  final String? imageUrl;
  final String? brand;

  const ScannedFoodProduct({
    required this.barcode,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize,
    this.imageUrl,
    this.brand,
  });

  /// Tạo bản sao với serving multiplier (ví dụ: ăn 1.5 khẩu phần hoặc 200g)
  ScannedFoodProduct scale(double multiplier) {
    return ScannedFoodProduct(
      barcode: barcode,
      name: name,
      calories: (calories * multiplier).round(),
      protein: (protein * multiplier).round(),
      carbs: (carbs * multiplier).round(),
      fat: (fat * multiplier).round(),
      servingSize: servingSize,
      imageUrl: imageUrl,
      brand: brand,
    );
  }
}

/// Dịch vụ tra cứu thông tin dinh dưỡng thực phẩm qua Open Food Facts REST API
class OpenFoodFactsService {
  OpenFoodFactsService._();
  static final OpenFoodFactsService instance = OpenFoodFactsService._();

  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Tra cứu mã vạch qua REST API Open Food Facts
  Future<ScannedFoodProduct?> fetchProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/$cleanBarcode.json');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FitnessTrackerApp - Android - Version 1.0.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('OpenFoodFacts API error status: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (data['status'] as num?)?.toInt() ?? 0;
      if (status != 1 || !data.containsKey('product')) {
        return null;
      }

      final product = data['product'] as Map<String, dynamic>;
      final nutriments = (product['nutriments'] as Map<String, dynamic>?) ?? {};

      // Ưu tiên tên tiếng Việt nếu có, rồi đến tiếng Anh, tên chung
      final name = product['product_name_vi']?.toString() ??
          product['product_name']?.toString() ??
          product['product_name_en']?.toString() ??
          'Sản phẩm ($cleanBarcode)';

      final brand = product['brands']?.toString();
      final servingSize = product['serving_size']?.toString();
      final imageUrl = product['image_front_url']?.toString() ??
          product['image_url']?.toString();

      // Năng lượng (kcal)
      int calories = (nutriments['energy-kcal_100g'] as num?)?.toInt() ??
          (nutriments['energy-kcal_serving'] as num?)?.toInt() ??
          (nutriments['energy-kcal'] as num?)?.toInt() ??
          0;

      // Nếu không có energy-kcal, kiểm tra energy_100g (kJ) và chuyển đổi sang kcal (1 kcal ≈ 4.184 kJ)
      if (calories <= 0) {
        final energyKj = (nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0;
        if (energyKj > 0) {
          calories = (energyKj / 4.184).round();
        }
      }

      // Đạm (Protein)
      final protein = ((nutriments['proteins_100g'] as num?)?.toDouble() ??
              (nutriments['proteins_serving'] as num?)?.toDouble() ??
              (nutriments['proteins'] as num?)?.toDouble() ??
              0.0)
          .round();

      // Tinh bột (Carbohydrates)
      final carbs = ((nutriments['carbohydrates_100g'] as num?)?.toDouble() ??
              (nutriments['carbohydrates_serving'] as num?)?.toDouble() ??
              (nutriments['carbohydrates'] as num?)?.toDouble() ??
              0.0)
          .round();

      // Chất béo (Fat)
      final fat = ((nutriments['fat_100g'] as num?)?.toDouble() ??
              (nutriments['fat_serving'] as num?)?.toDouble() ??
              (nutriments['fat'] as num?)?.toDouble() ??
              0.0)
          .round();

      return ScannedFoodProduct(
        barcode: cleanBarcode,
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingSize: servingSize,
        imageUrl: imageUrl,
        brand: brand,
      );
    } catch (e) {
      debugPrint('Lỗi tra cứu Open Food Facts: $e');
      return null;
    }
  }
}
