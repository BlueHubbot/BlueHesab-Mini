// DT-A: instants are stored as ISO-8601 UTC text with exactly three fraction
// digits, e.g. `2026-10-24T06:55:00.000Z` (DATA_MODEL §4, DT-01).

final RegExp _instantShape =
    RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$');

String _pad(int value, int width) => value.toString().padLeft(width, '0');

/// The stored text of [instant]: converted to UTC, microseconds truncated to
/// milliseconds (DT-A). Years outside 0…9999 are not representable.
String formatInstant(DateTime instant) {
  final DateTime u = instant.toUtc();
  if (u.year < 0 || u.year > 9999) {
    throw RangeError.range(u.year, 0, 9999, 'year');
  }
  return '${_pad(u.year, 4)}-${_pad(u.month, 2)}-${_pad(u.day, 2)}'
      'T${_pad(u.hour, 2)}:${_pad(u.minute, 2)}:${_pad(u.second, 2)}'
      '.${_pad(u.millisecond, 3)}Z';
}

/// Parses stored instant text. Only the exact DT-A shape is accepted (no
/// offsets, no other precision); the result is a UTC [DateTime].
DateTime parseInstant(String text) {
  if (!_instantShape.hasMatch(text)) {
    throw FormatException('not a DT-A instant', text);
  }
  final DateTime parsed = DateTime.parse(text);
  // DateTime.parse normalises out-of-range fields (e.g. month 13); reject
  // anything that does not format back to the same text.
  if (formatInstant(parsed) != text) {
    throw FormatException('not a valid DT-A instant', text);
  }
  return parsed;
}
