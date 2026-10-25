import 'dart:async';

import 'package:flutter/services.dart';

/// Light tick for toggles and +/- taps. Never throws (some platforms and
/// tests have no haptics).
void tapFeedback() {
  unawaited(HapticFeedback.selectionClick().catchError((_) {}));
}
