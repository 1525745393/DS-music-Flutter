import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_handler.dart';

/// 全局播放 Handler 句柄
/// 在 main() 中通过 override 提供
final audioHandlerProvider = Provider<DSPlayerHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});
