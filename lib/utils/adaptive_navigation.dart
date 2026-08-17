import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Opens a page full-screen on mobile, or as a centered modal on desktop.
Future<T?> pushAdaptivePage<T>(
  BuildContext context,
  Widget page, {
  double maxWidth = 560,
  double maxHeight = 720,
}) {
  if (context.isDesktop) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final height = MediaQuery.sizeOf(ctx).height;
        return Center(
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: height * 0.9 > maxHeight ? maxHeight : height * 0.9,
              ),
              child: page,
            ),
          ),
        );
      },
    );
  }

  return Navigator.of(context).push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
}
