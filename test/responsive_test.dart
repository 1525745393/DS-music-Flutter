import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/utils/responsive.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('deviceClassOf', () {
    testWidgets('手机宽度返回 compact', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      late DeviceClass cls;
      await tester.pumpWidget(Builder(
        builder: (ctx) {
          cls = deviceClassOf(ctx);
          return const SizedBox.shrink();
        },
      ));
      expect(cls, DeviceClass.compact);
    });
  });
}
