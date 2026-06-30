import 'package:flutter/cupertino.dart';
import '../../model/lyrics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// 逐行滚动歌词
class LyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final Duration position;
  final TextStyle? activeStyle;
  final TextStyle? inactiveStyle;
  final void Function(Duration position)? onSeek;

  const LyricsView({
    super.key,
    required this.lyrics,
    required this.position,
    this.activeStyle,
    this.inactiveStyle,
    this.onSeek,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  late ScrollController _controller;
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void didUpdateWidget(covariant LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIndex();
    _scrollToCurrent();
  }

  void _updateIndex() {
    final newIdx = widget.lyrics.indexAt(widget.position);
    if (newIdx != _currentIndex) {
      setState(() => _currentIndex = newIdx);
    }
  }

  void _scrollToCurrent() {
    if (_currentIndex < 0) return;
    if (!_controller.hasClients) return;
    final offset = (_currentIndex * 30.0) - 100;
    _controller.animateTo(
      offset.clamp(0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyrics.lines.isEmpty) {
      return Center(
        child: Text('暂无歌词',
            style: AppTextStyles.lyricsInactive),
      );
    }
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: 80),
      itemCount: widget.lyrics.lines.length,
      itemBuilder: (_, i) {
        final line = widget.lyrics.lines[i];
        final isActive = i == _currentIndex;
        return GestureDetector(
          onTap: () => widget.onSeek?.call(line.time),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 6,
            ),
            child: Center(
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                style: (isActive
                        ? (widget.activeStyle ?? AppTextStyles.lyricsActive)
                        : (widget.inactiveStyle ?? AppTextStyles.lyricsInactive))
                    .copyWith(
                  color: isActive
                      ? AppColors.textPrimaryDark
                      : AppColors.textAssistantDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
