import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/models/system_time.dart';

final simulatedTimeProvider =
    AsyncNotifierProvider<SimulatedTimeNotifier, DateTime>(
      SimulatedTimeNotifier.new,
    );

class SimulatedTimeNotifier extends AsyncNotifier<DateTime> {
  @override
  Future<DateTime> build() async {
    try {
      return await SystemTime.getSimulatedTime();
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> setSimulatedTime(DateTime simulatedTime) async {
    state = const AsyncLoading();
    try {
      await SystemTime.setSimulatedTime(simulatedTime);
      state = AsyncData(simulatedTime);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> clearSimulatedTime() async {
    state = const AsyncLoading();
    try {
      await SystemTime.clearSimulatedTime();
      state = AsyncData(DateTime.now());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
