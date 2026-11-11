import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  bool isError = false,
}) {
  final palette = context.palette;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: isError ? palette.danger : palette.accent,
      duration: const Duration(seconds: 2),
      content: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 19,
            color: isError ? Colors.white : palette.onAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isError ? Colors.white : palette.onAccent,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
