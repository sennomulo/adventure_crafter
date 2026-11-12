import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../services/adventure_service.dart';
import '../../services/roll_log_service.dart';

class RollLogPage extends StatelessWidget {
  const RollLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<AdventureService>();
    Get.put(RollLogService());
    return Obx(() {
      Get.find<AdventureService>().current.value;
      final records = service.current.value?.rollLog ?? <RollLogEntry>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('掷骰日志（本冒险）',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => Get.find<RollLogService>().clear(),
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('暂无掷骰记录'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = records[i];
                      final dt = DateTime.tryParse(r.time);
                      final t = dt == null
                          ? ''
                          : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
                      return ListTile(
                        dense: true,
                        leading: SizedBox(
                            width: 64,
                            child: Text(t,
                                style: Theme.of(context).textTheme.bodySmall)),
                        title: Text(r.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(r.detail),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}
