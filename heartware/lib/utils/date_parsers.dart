import 'package:intl/intl.dart';

int toInt(dynamic v) => (v is num) ? v.toInt() : int.parse(v.toString());

DateTime? parseFlexibleDT(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;

  final asNum = num.tryParse(s);
  if (asNum != null) {
    if (s.length >= 13) {
      return DateTime.fromMillisecondsSinceEpoch(asNum.toInt(), isUtc: true).toLocal();
    } else if (s.length >= 10) {
      return DateTime.fromMillisecondsSinceEpoch((asNum * 1000).toInt(), isUtc: true).toLocal();
    }
  }
  try { return DateTime.parse(s).toLocal(); } catch (_) {}
  for (final f in [
    'yyyy-MM-dd HH:mm:ss',
    'yyyy/MM/dd HH:mm:ss',
    'yyyy-MM-dd',
    'EEE, dd MMM yyyy HH:mm:ss',
  ]) {
    try {
      final df = (f.startsWith('EEE')) ? DateFormat(f, 'en_US') : DateFormat(f);
      return df.parseUtc(s).toLocal();
    } catch (_) {}
  }
  return null;
}
