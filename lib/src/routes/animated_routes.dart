import 'package:flutter/material.dart';

/// A reusable page route that fades and slides the new page in from the bottom (or from the given offset).
/// Use it in place of MaterialPageRoute for smoother entrance animations.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Offset beginOffset;

  FadeSlidePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.beginOffset = const Offset(0, 0.08), // slight upward motion
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
              child: SlideTransition(
                position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}
