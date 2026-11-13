import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('How to use the Adventure Crafter'.tr),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(context, 'Adventure outline'.tr,
                  'Assemble themes, then generate turning points one by one ahead of play to build the outline of a full adventure; expand the results into scene outlines yourself.'
                      .tr),
              _section(context, 'Adventure seed'.tr,
                  'Generate a single turning point when starting a new adventure and use it as the seed you grow into an adventure.'
                      .tr),
              _section(context, 'Opening scene'.tr,
                  'Use a generated turning point as an alternative way to create the first scene of a Mythic adventure.'
                      .tr),
              _section(context, 'Inspiration'.tr,
                  'When stuck, roll a single plot point or a list entry to get ideas; interpret the results yourself.'
                      .tr),
              const SizedBox(height: 8),
              Text(
                  'The software only rolls dice and looks up tables; all creative decisions are made by the player.'
                      .tr,
                  style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.primary)),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('OK'.tr)),
      ],
    ),
  );
}

Widget _section(BuildContext context, String title, String desc) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(desc, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
