// MotionProbe (MX-08, T-039): a test tool, not part of the app.
//
// It reads only `MotionRegistry` (filled by `MotionHandle` in debug and
// test) and never advances time: tests move time with `tester.pump(Duration)`.
// It has no tolerance of its own; each test states its own.

import 'package:bluehesab_mini/design/app_motion/app_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts running animations and reads animated values (MX-08).
final class MotionProbe {
  /// Creates a probe.
  const MotionProbe();

  /// Running non-loop animations built under [subtree] in the last frame.
  int activeCount(Finder subtree) => _under(subtree)
      .where((MotionRegistration r) => r.isActive && !r.isLoop)
      .length;

  /// Running loops (LP-01) built under [subtree] in the last frame.
  int activeLoopCount(Finder subtree) => _under(subtree)
      .where((MotionRegistration r) => r.isActive && r.isLoop)
      .length;

  /// Current [property] of [target]: the nearest tracked animation built at
  /// or above the single element [target] finds.
  ///
  /// Throws [StateError] when nothing at or above [target] tracks it.
  double value(Finder target, MotionProperty property) {
    final Element element = target.evaluate().single;
    final List<MotionRegistration> live = _live();
    Element? current = element;
    while (current != null) {
      for (final MotionRegistration r in live.reversed) {
        final Animation<double>? a = r.tracked(property);
        if (a != null && identical(r.context, current)) {
          return a.value;
        }
      }
      Element? parent;
      current.visitAncestorElements((Element e) {
        parent = e;
        return false;
      });
      current = parent;
    }
    throw StateError('no ${property.name} tracked at or above $target');
  }

  static List<MotionRegistration> _live() => MotionRegistry.entries
      .where((MotionRegistration r) => r.context.mounted)
      .toList();

  static Iterable<MotionRegistration> _under(Finder subtree) {
    final Set<Element> roots = subtree.evaluate().toSet();
    return _live().where((MotionRegistration r) {
      final Element e = r.context as Element;
      if (roots.contains(e)) {
        return true;
      }
      bool found = false;
      e.visitAncestorElements((Element a) {
        found = roots.contains(a);
        return !found;
      });
      return found;
    });
  }
}
