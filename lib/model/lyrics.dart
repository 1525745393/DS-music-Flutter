/// 歌词行：[时间, 文本]
class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});

  factory LyricLine.fromLrcLine(String line) {
    // 解析 LRC 格式行: [mm:ss.xx]文本
    final match = RegExp(r'^\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\](.*)$')
        .firstMatch(line);
    if (match == null) return null as dynamic;
    final m = int.parse(match.group(1)!);
    final s = int.parse(match.group(2)!);
    final rawMs = match.group(3);
    final ms = rawMs == null
        ? 0
        : (rawMs.length == 3
            ? int.parse(rawMs)
            : int.parse(rawMs.padRight(3, '0')));
    final text = match.group(4)?.trim() ?? '';
    return LyricLine(
      time: Duration(minutes: m, seconds: s, milliseconds: ms),
      text: text,
    );
  }
}

class Lyrics {
  final List<LyricLine> lines;
  final String? title;
  final String? artist;
  final String? album;

  const Lyrics({
    this.lines = const [],
    this.title,
    this.artist,
    this.album,
  });

  /// 解析 LRC 文本
  factory Lyrics.parse(String lrc) {
    final list = <LyricLine>[];
    String? t, a, al;
    for (final raw in lrc.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      // 元数据：[ti:title]、[ar:artist]、[al:album]
      final meta = RegExp(r'^\[(ti|ar|al):(.*)\]$').firstMatch(line);
      if (meta != null) {
        final k = meta.group(1);
        final v = meta.group(2) ?? '';
        if (k == 'ti') t = v;
        if (k == 'ar') a = v;
        if (k == 'al') al = v;
        continue;
      }
      try {
        final parsed = LyricLine.fromLrcLine(line);
        if (parsed != null && parsed.text.isNotEmpty) {
          list.add(parsed);
        }
      } catch (_) {
        // 忽略解析失败行，避免单行坏数据导致整体失败
      }
    }
    list.sort((a, b) => a.time.compareTo(b.time));
    return Lyrics(lines: list, title: t, artist: a, album: al);
  }

  /// 找到指定时间对应的当前行下标
  int indexAt(Duration position) {
    if (lines.isEmpty) return -1;
    int lo = 0, hi = lines.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time <= position) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}
