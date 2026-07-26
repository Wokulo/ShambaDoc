import 'package:shambadoc/ai/disease_model.dart';

class HistoryEntry {
  final ScanResult scan;
  final bool isSynced;
  final DateTime? syncedAt;

  HistoryEntry({required this.scan, this.isSynced = false, this.syncedAt});
}
