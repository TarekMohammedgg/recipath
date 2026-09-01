import 'package:flutter_test/flutter_test.dart';
import 'package:recipath/data/gtin_data/gtin_data.dart';
import 'package:recipath/data/unit_enum.dart';

void main() {
  group('GTINData.parseQuantity', () {
    test('parses simple grams', () {
      expect(GTINData.parseQuantity('500g'), (500.0, UnitEnum.g));
      expect(GTINData.parseQuantity('250 g'), (250.0, UnitEnum.g));
      expect(GTINData.parseQuantity('500 g ℮'), (500.0, UnitEnum.g));
      expect(GTINData.parseQuantity('100g e'), (100.0, UnitEnum.g));
    });

    test('parses decimals with dot and comma', () {
      expect(GTINData.parseQuantity('1.5 kg'), (1.5, UnitEnum.kg));
      expect(GTINData.parseQuantity('1,5 l'), (1.5, UnitEnum.l));
    });

    test('parses milliliters and liters', () {
      expect(GTINData.parseQuantity('330ml'), (330.0, UnitEnum.ml));
      expect(GTINData.parseQuantity('2 L'), (2.0, UnitEnum.l));
    });

    test('converts centiliters and deciliters to milliliters', () {
      expect(GTINData.parseQuantity('33 cl'), (330.0, UnitEnum.ml));
      expect(GTINData.parseQuantity('25cl'), (250.0, UnitEnum.ml));
      expect(GTINData.parseQuantity('1 dl'), (100.0, UnitEnum.ml));
    });

    test('converts milligrams to grams', () {
      expect(GTINData.parseQuantity('500 mg'), (0.5, UnitEnum.g));
    });

    test('parses multiplier expressions', () {
      expect(GTINData.parseQuantity('6 x 330 ml'), (1980.0, UnitEnum.ml));
      expect(GTINData.parseQuantity('4x100g'), (400.0, UnitEnum.g));
      expect(GTINData.parseQuantity('6 * 33 cl'), (1980.0, UnitEnum.ml));
      expect(GTINData.parseQuantity('6 × 330 ml'), (1980.0, UnitEnum.ml));
    });

    test('parses miscellaneous units', () {
      expect(GTINData.parseQuantity('12 oz'), (12.0, UnitEnum.oz));
      expect(GTINData.parseQuantity('1 lb'), (1.0, UnitEnum.lb));
      expect(GTINData.parseQuantity('4 pieces'), (4.0, UnitEnum.piece));
      expect(GTINData.parseQuantity('2 cans'), (2.0, UnitEnum.can));
    });

    test('returns null for missing or unparseable input', () {
      expect(GTINData.parseQuantity(null), isNull);
      expect(GTINData.parseQuantity(''), isNull);
      expect(GTINData.parseQuantity('unknown_format'), isNull);
      expect(GTINData.parseQuantity('12 fl oz'), isNull);
      expect(GTINData.parseQuantity('1 pot de 500 g'), isNull);
      expect(GTINData.parseQuantity('1,000 g'), isNull);
    });
  });

  group('GTINData.fromAPI', () {
    test('returns null when product is missing or status is 0', () {
      expect(GTINData.fromAPI('12345678', {'status': 0}), isNull);
      expect(GTINData.fromAPI('12345678', {'product': null}), isNull);
    });

    test('correctly parses product json', () {
      final json = {
        'status': 1,
        'product': {
          'product_name': 'Organic Milk',
          'quantity': '1 l',
          'nutriments': {
            'energy-kcal_100g': 64,
            'fat_100g': 3.5,
            'carbohydrates_100g': 4.8,
            'proteins_100g': 3.3,
            'fiber_100g': 0,
          },
        },
      };

      final gtin = GTINData.fromAPI('4000417001007', json);
      expect(gtin, isNotNull);
      expect(gtin!.barcode, '4000417001007');
      expect(gtin.name, 'Organic Milk');
      expect(gtin.amount, 1);
      expect(gtin.unit, UnitEnum.l);
      expect(gtin.kcal, 64);
      expect(gtin.fat, 3.5);
      expect(gtin.carbs, 4.8);
      expect(gtin.protein, 3.3);
      expect(gtin.fiber, 0);
    });

    test('falls back to generic_name when product_name is absent', () {
      final json = {
        'status': 1,
        'product': {'generic_name': 'Whole Grain Bread', 'quantity': '500g'},
      };

      final gtin = GTINData.fromAPI('4000417001008', json);
      expect(gtin, isNotNull);
      expect(gtin!.name, 'Whole Grain Bread');
      expect(gtin.amount, 500);
      expect(gtin.unit, UnitEnum.g);
    });

    test('returns null when quantity cannot be parsed safely', () {
      final json = {
        'status': 1,
        'product': {'product_name': 'Unknown Product', 'quantity': '12 fl oz'},
      };

      expect(GTINData.fromAPI('4000417001009', json), isNull);
    });
  });
}
