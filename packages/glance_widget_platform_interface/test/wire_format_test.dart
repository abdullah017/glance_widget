import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// The native plugins read these maps key by key. A rename on either side is
/// silent -- `data["imageFit"]` simply read null forever while Dart sent `fit`,
/// so the image fit setting never applied and nothing failed. These tests make
/// the wire format something you have to change on purpose.
void main() {
  group('ImageWidgetData wire format', () {
    test('carries exactly the keys the native side reads', () {
      const data = ImageWidgetData(
        title: 'T',
        imageUrl: 'https://example.com/a.png',
        imageBase64: 'AAAA',
        subtitle: 'S',
        deepLinkUri: 'app://x',
      );

      expect(data.toMap().keys.toSet(), <String>{
        'title',
        'imageUrl',
        'imageBase64',
        'subtitle',
        'fit',
        'deepLinkUri',
      });
    });

    test('sends the fit as its enum name', () {
      const data = ImageWidgetData(
        title: 'T',
        imageBase64: 'AAAA',
        fit: ImageFit.contain,
      );

      expect(data.toMap()['fit'], 'contain');
    });

    test('sends imageUrl through, which the native side must resolve', () {
      const data = ImageWidgetData(title: 'T', imageUrl: 'https://e.com/a.png');

      expect(data.toMap()['imageUrl'], 'https://e.com/a.png');
    });
  });

  group('ImageWidgetData validation', () {
    test('a widget with no image source at all is refused', () {
      const data = ImageWidgetData(title: 'T');

      expect(
        data.validate,
        throwsA(
          isA<GlanceWidgetValidationException>().having(
            (e) => e.field,
            'field',
            'imageUrl',
          ),
        ),
      );
    });

    test('either source on its own is enough', () {
      const ImageWidgetData(
        title: 'T',
        imageUrl: 'https://e.com/a.png',
      ).validate();
      const ImageWidgetData(title: 'T', imageBase64: 'AAAA').validate();
    });

    test('empty strings do not count as a source', () {
      const data = ImageWidgetData(title: 'T', imageUrl: '', imageBase64: '');

      expect(data.validate, throwsA(isA<GlanceWidgetValidationException>()));
    });
  });

  group('GlanceTheme wire format', () {
    test('carries exactly the keys the native side reads', () {
      expect(GlanceTheme.light().toMap().keys.toSet(), <String>{
        'backgroundColor',
        'textColor',
        'secondaryTextColor',
        'accentColor',
        'borderRadius',
        'isDark',
        'useDynamicColor',
      });
    });

    test('does not opt into dynamic colour unless asked', () {
      // A widget that silently repaints itself from the wallpaper the first
      // time someone upgrades the package is a bug report, not a feature.
      expect(GlanceTheme.light().toMap()['useDynamicColor'], isFalse);
      expect(GlanceTheme.dark().toMap()['useDynamicColor'], isFalse);
      expect(
        const GlanceTheme(
          backgroundColor: Color(0xFF000000),
          textColor: Color(0xFFFFFFFF),
        ).useDynamicColor,
        isFalse,
      );
    });

    test('sends the flag through when it is set', () {
      const theme = GlanceTheme(
        backgroundColor: Color(0xFF000000),
        textColor: Color(0xFFFFFFFF),
        useDynamicColor: true,
      );

      expect(theme.toMap()['useDynamicColor'], isTrue);
    });

    test('copyWith carries the flag both ways', () {
      final on = GlanceTheme.light().copyWith(useDynamicColor: true);
      expect(on.useDynamicColor, isTrue);
      expect(on.copyWith(useDynamicColor: false).useDynamicColor, isFalse);
    });

    test('the explicit colours still travel when dynamic colour is on', () {
      // They are the fallback for every device below Android 12, so dropping
      // them would leave those devices with nothing to paint with.
      const theme = GlanceTheme(
        backgroundColor: Color(0xFF102030),
        textColor: Color(0xFFAABBCC),
        useDynamicColor: true,
      );

      expect(theme.toMap()['backgroundColor'], 0xFF102030);
      expect(theme.toMap()['textColor'], 0xFFAABBCC);
    });
  });
}
