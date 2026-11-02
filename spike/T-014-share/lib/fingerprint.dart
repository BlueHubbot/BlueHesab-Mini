import 'dart:convert';

/// FNV-1a 32-bit over the UTF-8 bytes of [text], as 8 lowercase hex digits.
///
/// The spike logs this fingerprint and the code-unit length instead of the
/// text itself (CAPTURE_PIPELINE §6: logs never carry message text), and CI
/// computes the same values in Python from the text it sent.
String fnv1a32Hex(String text) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// The single log line CI looks for in logcat (tag `flutter`).
String shareMarker(String source, String text) =>
    'SPIKE_SHARE source=$source chars=${text.length} fnv=${fnv1a32Hex(text)}';
