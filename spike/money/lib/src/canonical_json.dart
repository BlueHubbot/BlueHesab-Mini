// T-002 spike: canonical JSON for the backup checksum (BACKUP_RESTORE:
// "canonical JSON (sorted keys, no whitespace) for hashing"; DATA_MODEL §10).
//
// Rules:
// - Object keys are sorted by UTF-16 code unit (String.compareTo), the same
//   order RFC 8785 uses.
// - Strings use the escaping of dart:convert (`"`, `\`, control characters);
//   all other characters, Persian text and ZWNJ included, are written as is.
// - Allowed values: null, bool, String, int, List and Map with String keys.
//   Any other value throws: money is a decimal string (DD-02), never a JSON
//   number with a fraction (RKX-01).

import 'dart:convert';

/// Encodes [value] canonically. Throws [ArgumentError] for values that a
/// backup may not contain.
String canonicalJson(Object? value) {
  final buffer = StringBuffer();
  _write(value, buffer);
  return buffer.toString();
}

void _write(Object? value, StringBuffer out) {
  if (value == null) {
    out.write('null');
  } else if (value is bool) {
    out.write(value ? 'true' : 'false');
  } else if (value is String) {
    out.write(jsonEncode(value));
  } else if (value is int) {
    out.write(value.toString());
  } else if (value is List<Object?>) {
    out.write('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) {
        out.write(',');
      }
      _write(value[i], out);
    }
    out.write(']');
  } else if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    out.write('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        out.write(',');
      }
      out
        ..write(jsonEncode(keys[i]))
        ..write(':');
      _write(value[keys[i]], out);
    }
    out.write('}');
  } else {
    throw ArgumentError.value(
      value,
      'value',
      'not allowed in canonical JSON (money is a decimal string, DD-02)',
    );
  }
}
