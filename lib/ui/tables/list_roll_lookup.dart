import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';

void showListRollLookup(
  BuildContext context, {
  required String title,
  required PagedList list,
  required List<String> defaults,
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
            Text('Physical dice: roll yourself and read the result from the table.'
                .tr),
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
                    leading: SizedBox(
                      width: 96,
                      child: Text(
                          '${'Page @page'.trParams({'page': '${pageIdx + 1}'})} · ${row * 4 + 1}~${row * 4 + 4}'),
                    ),
                    title: Text(
                      entry?.name ?? defaults[row],
                      style: entry == null
                          ? const TextStyle(color: Colors.grey)
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
