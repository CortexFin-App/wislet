import 'dart:async';
import 'package:wislet/services/sync_service.dart';

final Expando<Timer> _autoSyncTimers = Expando<Timer>('autoSyncTimer');

extension SyncServiceAutoStart on SyncService {
  void ensureStarted({Duration interval = const Duration(minutes: 15)}) {
    final existing = _autoSyncTimers[this];
    existing?.cancel();
    _autoSyncTimers[this] = Timer.periodic(interval, (_) {
      synchronize();
    });
  }

  void stopAutoSync() {
    final existing = _autoSyncTimers[this];
    existing?.cancel();
    _autoSyncTimers[this] = null;
  }
}
