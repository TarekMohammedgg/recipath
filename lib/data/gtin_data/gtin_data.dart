import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:recipath/data/unit_enum.dart';

part 'gtin_data.freezed.dart';

@freezed
abstract class GTINData with _$GTINData {
  const factory GTINData({
    required String barcode,
    required String name,
    required double amount,
    required UnitEnum unit,
    double? kcal,
    double? fat,
    double? carbs,
    double? protein,
    double? fiber,
  }) = _GTINData;

  static final RegExp multiplierRegEx = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s*[xX*×]\s*(\d+(?:[.,]\d+)?)\s*([a-zA-Z]+)(?:\s*[e℮])?\s*$',
  );
  static final RegExp quantityRegEx = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s*([a-zA-Z]+)(?:\s*[e℮])?\s*$',
  );

  static (double, UnitEnum)? parseQuantity(String? quantity) {
    final trimmed = quantity?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    // Check for multiplier pattern first, e.g. "6 x 330 ml" or "4x100g"
    final multMatch = multiplierRegEx.firstMatch(trimmed);
    if (multMatch != null) {
      final count = _parseNumber(multMatch.group(1)!);
      final base = _parseNumber(multMatch.group(2)!);
      final rawUnit = multMatch.group(3)!.toLowerCase();
      final resolvedUnit = _resolveUnit(rawUnit);
      if (count == null || base == null || resolvedUnit == null) return null;

      final (factor, unit) = resolvedUnit;
      return (count * base * factor, unit);
    }

    // Standard pattern, e.g. "500 g", "1.5 l", "33 cl", "500g e"
    final singleMatch = quantityRegEx.firstMatch(trimmed);
    if (singleMatch != null) {
      final base = _parseNumber(singleMatch.group(1)!);
      final rawUnit = singleMatch.group(2)!.toLowerCase();
      final resolvedUnit = _resolveUnit(rawUnit);
      if (base == null || resolvedUnit == null) return null;

      final (factor, unit) = resolvedUnit;
      return (base * factor, unit);
    }

    return null;
  }

  static double? _parseNumber(String value) {
    final separator = value.contains(',')
        ? ','
        : value.contains('.')
        ? '.'
        : null;

    if (separator != null) {
      final parts = value.split(separator);
      final isAmbiguousThousandsFormat =
          parts.first != '0' && parts.last.length == 3;
      if (isAmbiguousThousandsFormat) return null;
    }

    return double.tryParse(value.replaceAll(',', '.'));
  }

  static (double, UnitEnum)? _resolveUnit(String unitStr) {
    switch (unitStr) {
      // Volume
      case 'ml':
      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
        return (1.0, UnitEnum.ml);
      case 'cl':
      case 'centiliter':
      case 'centiliters':
      case 'centilitre':
      case 'centilitres':
        return (10.0, UnitEnum.ml);
      case 'dl':
      case 'deciliter':
      case 'deciliters':
      case 'decilitre':
      case 'decilitres':
        return (100.0, UnitEnum.ml);
      case 'l':
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        return (1.0, UnitEnum.l);
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return (1.0, UnitEnum.tsp);
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return (1.0, UnitEnum.tbsp);
      case 'cup':
      case 'cups':
        return (1.0, UnitEnum.cup);

      // Weight
      case 'g':
      case 'gr':
      case 'gram':
      case 'grams':
      case 'gramme':
      case 'grammes':
        return (1.0, UnitEnum.g);
      case 'mg':
      case 'milligram':
      case 'milligrams':
      case 'milligramme':
      case 'milligrammes':
        return (0.001, UnitEnum.g);
      case 'kg':
      case 'kilo':
      case 'kilos':
      case 'kilogram':
      case 'kilograms':
      case 'kilogramme':
      case 'kilogrammes':
        return (1.0, UnitEnum.kg);
      case 'oz':
      case 'ounce':
      case 'ounces':
        return (1.0, UnitEnum.oz);
      case 'lb':
      case 'lbs':
      case 'pound':
      case 'pounds':
        return (1.0, UnitEnum.lb);

      // Misc
      case 'pinch':
      case 'pinches':
        return (1.0, UnitEnum.pinch);
      case 'clove':
      case 'cloves':
        return (1.0, UnitEnum.clove);
      case 'can':
      case 'cans':
      case 'dose':
      case 'dosen':
        return (1.0, UnitEnum.can);
      case 'piece':
      case 'pieces':
      case 'stk':
        return (1.0, UnitEnum.piece);

      default:
        return null;
    }
  }

  static GTINData? fromAPI(String barcode, Map<String, dynamic> json) {
    if (json['product'] == null || json['status'] == 0) {
      return null;
    }

    final product = json['product'] as Map<String, dynamic>;

    final name =
        (product['product_name'] ?? product["generic_name"] ?? '') as String;
    final quantity = product['quantity'] as String?;
    final nutriments = product['nutriments'] as Map<String, dynamic>?;

    final kcal = nutriments?['energy-kcal_100g'] as num?;
    final fat = nutriments?['fat_100g'] as num?;
    final carbs = nutriments?['carbohydrates_100g'] as num?;
    final protein = nutriments?['proteins_100g'] as num?;
    final fiber = nutriments?['fiber_100g'] as num?;

    final parsedQuantity = parseQuantity(quantity);
    if (parsedQuantity == null) return null;

    final (amount, unit) = parsedQuantity;

    return GTINData(
      barcode: barcode,
      name: name,
      amount: amount,
      unit: unit,
      kcal: kcal?.toDouble(),
      fat: fat?.toDouble(),
      carbs: carbs?.toDouble(),
      protein: protein?.toDouble(),
      fiber: fiber?.toDouble(),
    );
  }
}
