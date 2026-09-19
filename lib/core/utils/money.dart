/// Formats a Tanzanian shilling amount with thousands separators, e.g.
/// 1240000 -> "Tsh 1,240,000". Rounds to the nearest shilling — this app
/// never deals in cents.
String formatTsh(double value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final str = rounded.abs().toString();

  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromEnd = str.length - i;
    buf.write(str[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
  }

  return isNegative ? '-Tsh $buf' : 'Tsh $buf';
}
