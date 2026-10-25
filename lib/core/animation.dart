import 'package:flutter/widgets.dart';

/// Animation length that respects the system "remove animations" setting.
Duration animDuration(BuildContext context, [int milliseconds = 300]) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: milliseconds);
