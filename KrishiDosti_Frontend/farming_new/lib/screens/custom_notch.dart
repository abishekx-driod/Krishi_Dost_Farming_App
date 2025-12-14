import 'package:flutter/material.dart';

class BigFabNotch extends NotchedShape {
  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || guest.isEmpty) return Path()..addRect(host);

    final double notchRadius = guest.width * 0.60; // Larger notch

    final Path path = Path()..moveTo(host.left, host.top);

    final double notchCenter = guest.center.dx;
    final double leftNotch = notchCenter - notchRadius;
    final double rightNotch = notchCenter + notchRadius;

    // Left straight line
    path.lineTo(leftNotch, host.top);

    // Big arc notch
    path.quadraticBezierTo(
      notchCenter,
      host.top - notchRadius * 0.7,
      rightNotch,
      host.top,
    );

    // Right straight line
    path.lineTo(host.right, host.top);
    path.lineTo(host.right, host.bottom);
    path.lineTo(host.left, host.bottom);

    return path;
  }
}
