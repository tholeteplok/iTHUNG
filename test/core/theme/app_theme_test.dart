import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme Typography & Font Centralization', () {
    test('mathNumberStyle uses local JetBrainsMono font family', () {
      final style = AppTheme.mathNumberStyle();
      expect(style.fontFamily, equals('JetBrainsMono'));
      expect(style.fontWeight, equals(FontWeight.w800));
      expect(style.fontSize, equals(38));
      expect(style.color, equals(AppTheme.colorEspresso));
    });

    test('statNumberStyle uses local JetBrainsMono font family', () {
      final style = AppTheme.statNumberStyle();
      expect(style.fontFamily, equals('JetBrainsMono'));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.fontSize, equals(24));
    });

    test('answerButtonStyle uses local JetBrainsMono font family', () {
      final style = AppTheme.answerButtonStyle();
      expect(style.fontFamily, equals('JetBrainsMono'));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.fontSize, equals(26));
    });

    test('brandTitleStyle uses CoffeeSpark font family', () {
      final style = AppTheme.brandTitleStyle();
      expect(style.fontFamily, equals('CoffeeSpark'));
      expect(style.fontSize, equals(62));
    });

    test('brandOutlineStyle uses CoffeeSpark font family with stroke paint', () {
      final style = AppTheme.brandOutlineStyle();
      expect(style.fontFamily, equals('CoffeeSpark'));
      expect(style.fontSize, equals(66));
      expect(style.foreground, isNotNull);
      expect(style.foreground?.style, equals(PaintingStyle.stroke));
    });
  });
}
