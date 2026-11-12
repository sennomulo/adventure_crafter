import 'package:get/get.dart';

class RollRecord {
  final DateTime time;
  final String label;
  final String detail;

  RollRecord({required this.time, required this.label, required this.detail});
}

class RollLogService extends GetxService {
  final records = <RollRecord>[].obs;

  void log(String label, String detail) {
    records.insert(0, RollRecord(time: DateTime.now(), label: label, detail: detail));
  }

  void clear() => records.clear();
}
