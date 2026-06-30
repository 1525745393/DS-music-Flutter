import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/player/network_type_watcher.dart';

void main() {
  group('NetTypeX', () {
    test('isHighBandwidth 仅 wifi/ethernet 为 true', () {
      expect(NetType.wifi.isHighBandwidth, isTrue);
      expect(NetType.ethernet.isHighBandwidth, isTrue);
      expect(NetType.mobile.isHighBandwidth, isFalse);
      expect(NetType.none.isHighBandwidth, isFalse);
      expect(NetType.unknown.isHighBandwidth, isFalse);
      expect(NetType.vpn.isHighBandwidth, isFalse);
    });

    test('label 非空', () {
      for (final t in NetType.values) {
        expect(t.label.isNotEmpty, isTrue);
      }
    });
  });
}
