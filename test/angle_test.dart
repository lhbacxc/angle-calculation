import 'package:flutter_test/flutter_test.dart';
import 'package:angle_calculator/models/angle.dart';

void main() {
  group('Angle Tests', () {
    test('Parse angle from string', () {
      final angle = Angle.fromString('11°22′33″');
      expect(angle.degrees, 11);
      expect(angle.minutes, 22);
      expect(angle.seconds, 33.0);
      expect(angle.isNegative, false);
    });

    test('Convert to decimal', () {
      final angle = Angle(degrees: 45, minutes: 30, seconds: 0);
      expect(angle.toDecimal(), closeTo(45.5, 0.001));
    });

    test('Convert from decimal', () {
      final angle = Angle.fromDecimal(45.5);
      expect(angle.degrees, 45);
      expect(angle.minutes, 30);
      expect(angle.seconds, closeTo(0, 0.1));
    });

    test('Addition', () {
      final a1 = Angle(degrees: 10, minutes: 30, seconds: 45);
      final a2 = Angle(degrees: 20, minutes: 40, seconds: 50);
      final result = a1 + a2;
      expect(result.degrees, 31);
      expect(result.minutes, 11);
      expect(result.seconds, closeTo(35, 0.1));
    });

    test('Subtraction', () {
      final a1 = Angle(degrees: 80, minutes: 55, seconds: 66);
      final a2 = Angle(degrees: 11, minutes: 22, seconds: 33);
      final result = a1 - a2;
      expect(result.degrees, 69);
      expect(result.minutes, 33);
      expect(result.seconds, closeTo(33, 0.1));
    });

    test('Multiplication', () {
      final angle = Angle(degrees: 45, minutes: 30, seconds: 0);
      final result = angle * 2;
      expect(result.degrees, 91);
      expect(result.minutes, 0);
      expect(result.seconds, closeTo(0, 0.1));
    });

    test('Division', () {
      final angle = Angle(degrees: 90, minutes: 0, seconds: 0);
      final result = angle / 2;
      expect(result.degrees, 45);
      expect(result.minutes, 0);
      expect(result.seconds, closeTo(0, 0.1));
    });

    test('Normalize angle with overflow', () {
      final angle = Angle(degrees: 10, minutes: 70, seconds: 80);
      final normalized = angle.normalize();
      expect(normalized.degrees, 11);
      expect(normalized.minutes, 11);
      expect(normalized.seconds, closeTo(20, 0.1));
    });

    test('Negative angle', () {
      final angle = Angle(degrees: 10, minutes: 20, seconds: 30, isNegative: true);
      expect(angle.toDecimal(), lessThan(0));
      expect(angle.toString(), startsWith('-'));
    });
  });
}
