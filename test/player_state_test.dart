import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/provider/player_provider.dart';
import 'package:ds_music_flutter/model/song.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ProviderContainer _container() => ProviderContainer();

void main() {
  group('PlayerStateNotifier', () {
    late ProviderContainer container;
    setUp(() {
      container = _container();
    });
    tearDown(() => container.dispose());

    Song _song(String id) =>
        Song.fromJson({'id': id, 'title': 'S$id', 'duration': 60});

    test('setQueue 设置队列与当前歌曲', () {
      final notifier = container.read(playerStateProvider.notifier);
      notifier.setQueue([_song('1'), _song('2')], startIndex: 1);
      final s = container.read(playerStateProvider);
      expect(s.queue.length, 2);
      expect(s.currentIndex, 1);
      expect(s.current?.id, '2');
    });

    test('next 顺序模式递增', () {
      final notifier = container.read(playerStateProvider.notifier);
      notifier.setQueue([_song('1'), _song('2'), _song('3')], startIndex: 0);
      notifier.next();
      expect(container.read(playerStateProvider).currentIndex, 1);
      notifier.next();
      notifier.next();
      // 末位 next 应回到 0
      expect(container.read(playerStateProvider).currentIndex, 0);
    });

    test('prev 顺序模式递减并循环', () {
      final notifier = container.read(playerStateProvider.notifier);
      notifier.setQueue([_song('1'), _song('2')], startIndex: 0);
      notifier.prev(); // 0 -> 1
      expect(container.read(playerStateProvider).currentIndex, 1);
    });

    test('next 随机模式不越界', () {
      final notifier = container.read(playerStateProvider.notifier);
      notifier.setMode(PlayMode.shuffle);
      notifier.setQueue(List.generate(10, (i) => _song('$i')), startIndex: 0);
      for (var i = 0; i < 20; i++) {
        notifier.next();
        final idx = container.read(playerStateProvider).currentIndex;
        expect(idx, inInclusiveRange(0, 9));
      }
    });

    test('removeAt 调整 currentIndex', () {
      final notifier = container.read(playerStateProvider.notifier);
      notifier.setQueue([_song('1'), _song('2'), _song('3')], startIndex: 1);
      notifier.removeAt(0); // 移除"1"：currentIndex 由 1 -> 0
      final s = container.read(playerStateProvider);
      expect(s.queue.length, 2);
      expect(s.currentIndex, 0);
      expect(s.current?.id, '2');
    });

    test('move 重排队列', () {
      final notifier = container.read(playerStateProvider.notifier);
      notifier.setQueue([_song('1'), _song('2'), _song('3')], startIndex: 0);
      notifier.move(0, 2); // [2,3,1]
      final s = container.read(playerStateProvider);
      expect(s.queue.map((e) => e.id).toList(), ['2', '3', '1']);
    });
  });
}
