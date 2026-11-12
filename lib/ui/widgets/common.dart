import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget weightBadge(BuildContext context, int count) {
  if (count <= 1) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text('x$count',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
  );
}

Future<bool> confirmDialog(BuildContext context, String title, String content) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel'.tr)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('OK'.tr)),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> textInputDialog(BuildContext context, String title,
    {String? initial, String hint = ''}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel'.tr)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text('OK'.tr)),
      ],
    ),
  );
  return result;
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}
