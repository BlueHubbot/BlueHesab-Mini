import 'package:flutter_test/flutter_test.dart';
import 'package:spike_fonts/digits.dart';

// T-015: the spike's typed-amount parser (no font needed). BigInt only.

void main() {
  test('Persian and Arabic-Indic digits become ASCII', () {
    expect(toAsciiDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    expect(toAsciiDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(toAsciiDigits('abc'), 'abc');
  });

  test('separators are dropped, anything else rejects', () {
    expect(parseTypedAmount('۱۲۳٬۴۵۶'), BigInt.from(123456));
    expect(parseTypedAmount('1,234'), BigInt.from(1234));
    expect(parseTypedAmount('۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹۹'), BigInt.parse('999999999999999999'));
    expect(parseTypedAmount(''), isNull);
    expect(parseTypedAmount('۱۲.۵'), isNull);
    expect(parseTypedAmount('-۵'), isNull);
  });
}
