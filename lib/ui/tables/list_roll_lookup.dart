import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';

/// [onSelect] 非空时进入"实体骰确认"模式：点选行即确认该出目（空行也可选，
/// 由调用方按默认提示处理）。
void showListRollLookup(
  BuildContext context, {
  required String title,
  required PagedList list,
  required List<String> defaults,
  void Function(ListEntry? entry, int pageIdx, int rowIdx)? onSelect,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                onSelect == null
                    ? 'Physical dice: roll yourself and read the result from the table.'
                        .tr
                    : 'Physical dice: pick the row matching your roll to confirm.'
                        .tr,
                style: Theme.of(context).textTheme.bodySmall),
            if (list.pages.length > 1)
              Text('Paged list: roll 1d@pages to pick a page, then 1d100 for the row (row n covers 4n-3 ~ 4n).'
                      .trParams({'pages': '${list.pages.length}'})),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: list.pages.length * 25,
                itemBuilder: (context, i) {
                  final pageIdx = i ~/ 25;
                  final row = i % 25;
                  final entry = list.entryById(list.pages[pageIdx][row]);
                  return ListTile(
                    dense: true,
                    onTap: onSelect == null
                        ? null
                        : () {
                            Navigator.pop(dialogContext);
                            onSelect(entry, pageIdx, row);
                          },
                    leading: SizedBox(
                      width: 96,
                      child: Text(
                          '${'Page @page'.trParams({'page': '${pageIdx + 1}'})} · ${row * 4 + 1}~${row * 4 + 4}'),
                    ),
                    title: Text(
                      entry?.name ?? defaults[row],
                      style: entry == null
                          ? TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close'.tr)),
      ],
    ),
  );
}
