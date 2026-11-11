import 'dart:math' as math;

import 'package:flutter/material.dart';

/// На широком экране (Chrome) контент не растягивается на всю ширину.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(constraints.maxWidth, maxWidth),
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
