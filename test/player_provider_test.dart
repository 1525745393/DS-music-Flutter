import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ds_music_flutter/model/song.dart';
import 'package:ds_music_flutter/provider/player_provider.dart';

void main() {
  group('PlayerStateNotifier', () {
    late ProviderContainer container;
    late PlayerStateNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(playerStateProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('setQueue 设置队列', () {
      final songs = List.generate(5, (i) => Song.fromJson({
        'id': '$i',
        'title': 'song $i',
        'duration': 60,
      }));
      notifier.setQueue(songs, startIndex: 2);
      final state = container.read(playerStateProvider);
      expect(state.queue.length, 5);
      expect(state.currentIndex, 2);
      expect(state.current?.title, 'song 2');
    });

    test('addToQueue 追加', () {
      notifier.setQueue([Song.fromJson({'id': '1', 'title': 'a', 'duration': 60})]);
      notifier.addToQueue(Song.fromJson({'id': '2', 'title': 'b', 'duration': 60}));
      final s = container.read(playerStateProvider);
      expect(s.queue.length, 2);
    });

    test('removeAt 当前索引前删除', () {
      final songs = List.generate(3, (i) => Song.fromJson({
        'id': '$i',
        'title': 's$i',
        'duration': 60,
      }));
      notifier.setQueue(songs, startIndex: 1);
      notifier.removeAt(0);
      final s = container.read(playerStateProvider);
      expect(s.queue.length, 2);
      expect(s.current?.id, '1');
    });

    test('next/prev 循环', () {
      final songs = List.generate(3, (i) => Song.fromJson({
        'id': '$i',
        'title': 's$i',
        'duration': 60,
      }));
      notifier.setQueue(songs, startIndex: 0);
      notifier.next();
      notifier.next();
      notifier.next(); // 循环
      expect(container.read(playerStateProvider).currentIndex, 0);
      notifier.prev();
      expect(container.read(playerStateProvider).currentIndex, 2);
    });

    test('setMode 切换', () {
      notifier.setMode(PlayMode.shuffle);
      expect(container.read(playerStateProvider).mode, PlayMode.shuffle);
    });
  });
}
