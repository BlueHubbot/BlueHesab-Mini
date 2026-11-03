// A small Dart lexer for the `rules` stage (T-016, MC-24, VR-03).
//
// It splits a source file into three views so text patterns match only where
// they should:
// - `code`: the source with every comment and every string-literal body
//   replaced by spaces (newlines kept, so offsets and lines stay exact);
//   the code inside `${…}` interpolation stays visible.
// - `strings`: each string-literal body as written in the source (escapes not
//   decoded), without its quotes and without interpolated code.
// - `comments`: each comment with its text.
// No dependency (CB-9): the analyzer package is not used.

/// A string literal (or one literal part between interpolations).
final class StringPart {
  const StringPart(this.line, this.text, {required this.raw});

  /// 1-based line where the part starts.
  final int line;

  /// The body as written in the source.
  final String text;

  /// True for `r'…'` literals (escapes are not escapes).
  final bool raw;
}

/// A line or block comment.
final class CommentPart {
  const CommentPart(this.line, this.text);

  /// 1-based line where the comment starts.
  final int line;

  /// The comment including its `//` or `/*` markers.
  final String text;
}

/// The three views of one source file.
final class Lexed {
  Lexed._(this.source, this.code, this.strings, this.comments, this._lineStarts);

  /// Lexes [source]. Never throws: an unterminated literal or comment ends at
  /// the end of the file (or of the line for a one-line string).
  factory Lexed(String source) {
    final _Lexer l = _Lexer(source)..code(0, interpolation: false);
    return Lexed._(source, String.fromCharCodes(l.masked), l.strings,
        l.comments, l.lineStarts);
  }

  final String source;
  final String code;
  final List<StringPart> strings;
  final List<CommentPart> comments;
  final List<int> _lineStarts;

  /// 1-based line of the character at [offset].
  int lineOf(int offset) => _lineIn(_lineStarts, offset);
}

int _lineIn(List<int> starts, int offset) {
  int lo = 0;
  int hi = starts.length - 1;
  while (lo < hi) {
    final int mid = (lo + hi + 1) >> 1;
    if (starts[mid] <= offset) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo + 1;
}

const int _nl = 0x0A;
const int _space = 0x20;
const int _slash = 0x2F;
const int _star = 0x2A;
const int _backslash = 0x5C;
const int _dollar = 0x24;
const int _lbrace = 0x7B;
const int _rbrace = 0x7D;
const int _sq = 0x27;
const int _dq = 0x22;

bool _isIdent(int c) =>
    (c >= 0x30 && c <= 0x39) ||
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    c == 0x5F ||
    c == _dollar;

final class _Lexer {
  _Lexer(this.s)
      : n = s.length,
        masked = s.codeUnits.toList(),
        lineStarts = _starts(s);

  final String s;
  final int n;
  final List<int> masked;
  final List<StringPart> strings = <StringPart>[];
  final List<CommentPart> comments = <CommentPart>[];
  final List<int> lineStarts;

  static List<int> _starts(String s) {
    final List<int> out = <int>[0];
    for (int i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) == _nl) {
        out.add(i + 1);
      }
    }
    return out;
  }

  int _at(int i) => i >= 0 && i < n ? s.codeUnitAt(i) : -1;

  void _mask(int from, int to) {
    for (int i = from; i < to && i < n; i++) {
      if (masked[i] != _nl) {
        masked[i] = _space;
      }
    }
  }

  int _lineOf(int offset) => _lineIn(lineStarts, offset);

  /// Lexes code from [i]. With [interpolation] it stops after the `}` that
  /// closes `${`, and returns the index after it.
  int code(int i, {required bool interpolation}) {
    int depth = 0;
    while (i < n) {
      final int c = s.codeUnitAt(i);
      if (c == _slash && _at(i + 1) == _slash) {
        int j = i;
        while (j < n && s.codeUnitAt(j) != _nl) {
          j++;
        }
        comments.add(CommentPart(_lineOf(i), s.substring(i, j)));
        _mask(i, j);
        i = j;
        continue;
      }
      if (c == _slash && _at(i + 1) == _star) {
        int j = i + 2;
        int nest = 1;
        while (j < n && nest > 0) {
          if (s.codeUnitAt(j) == _slash && _at(j + 1) == _star) {
            nest++;
            j += 2;
          } else if (s.codeUnitAt(j) == _star && _at(j + 1) == _slash) {
            nest--;
            j += 2;
          } else {
            j++;
          }
        }
        comments.add(CommentPart(_lineOf(i), s.substring(i, j)));
        _mask(i, j);
        i = j;
        continue;
      }
      if (c == _sq || c == _dq) {
        final int p = _at(i - 1);
        final bool raw = (p == 0x72 || p == 0x52) && !_isIdent(_at(i - 2));
        i = _string(i, raw: raw);
        continue;
      }
      if (interpolation) {
        if (c == _lbrace) {
          depth++;
        } else if (c == _rbrace) {
          if (depth == 0) {
            return i + 1;
          }
          depth--;
        }
      }
      i++;
    }
    return i;
  }

  /// Lexes the string literal whose opening quote is at [i]; returns the
  /// index after its closing quote(s).
  int _string(int i, {required bool raw}) {
    final int q = s.codeUnitAt(i);
    final bool triple = _at(i + 1) == q && _at(i + 2) == q;
    final int open = triple ? 3 : 1;
    int j = i + open;
    int partStart = j;
    final StringBuffer part = StringBuffer();
    void flush() {
      if (part.isNotEmpty) {
        strings.add(StringPart(_lineOf(partStart), part.toString(), raw: raw));
        part.clear();
      }
    }

    while (j < n) {
      final int c = s.codeUnitAt(j);
      if (!triple && c == _nl) {
        break; // unterminated one-line string: stop at the line end
      }
      if (c == q &&
          (!triple || (_at(j + 1) == q && _at(j + 2) == q))) {
        flush();
        _mask(i + open, j);
        return j + open;
      }
      if (!raw && c == _backslash) {
        part.writeCharCode(c);
        if (j + 1 < n) {
          part.writeCharCode(s.codeUnitAt(j + 1));
        }
        j += 2;
        continue;
      }
      if (!raw && c == _dollar && _at(j + 1) == _lbrace) {
        flush();
        _mask(i + open, j);
        final int after = code(j + 2, interpolation: true);
        // Keep the interpolated code visible; continue the literal after it.
        i = after - open; // so the next _mask starts at `after`
        j = after;
        partStart = j;
        continue;
      }
      part.writeCharCode(c);
      j++;
    }
    flush();
    _mask(i + open, j);
    return j;
  }
}
