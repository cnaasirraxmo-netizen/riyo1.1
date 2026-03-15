import 'dart:async';

class SrtParser {
  static List<SubtitleEntry> parse(String content) {
    final List<SubtitleEntry> entries = [];
    final RegExp regExp = RegExp(
      r'(\d+)\n(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\n([\s\S]*?)(?=\n\n|\n*$)',
      multiLine: true,
    );

    final matches = regExp.allMatches(content);
    for (final match in matches) {
      final start = _parseTime(match.group(2)!);
      final end = _parseTime(match.group(3)!);
      final text = match.group(4)!.replaceAll('\n', ' ').trim();
      entries.add(SubtitleEntry(start: start, end: end, text: text));
    }
    return entries;
  }

  static Duration _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final secondsParts = parts[2].split(',');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(secondsParts[0]),
      milliseconds: int.parse(secondsParts[1]),
    );
  }
}

class SubtitleEntry {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleEntry({required this.start, required this.end, required this.text});
}
