import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorMonitoringService {
  static Future<void> init(Future<void> Function() appRunner) async {
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://561d5e2437165af9ed2caa7abecc2424@o4509628768452608.ingest.de.sentry.io/4509628789293136';
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
        options.sendDefaultPii = true;
      },
      appRunner: appRunner,
    );
  }

  static Future<void> capture(
    dynamic exception, {
    dynamic stackTrace,
    String? reason,
  }) async {
    if (kReleaseMode) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: reason != null ? Hint.withMap({'reason': reason}) : null,
      );
    } else {
      debugPrint('--- CAPTURED EXCEPTION ---');
      debugPrint('Reason: $reason');
      debugPrint('Exception: $exception');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('--------------------------');
    }
  }
}
