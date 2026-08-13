import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/features/cycle_tracking/data/repositories/cycle_repository.dart';
import 'package:oummi3/features/pregnancy/data/repositories/pregnancy_repository.dart';
import 'package:oummi3/features/cycle_tracking/data/models/cycle_model.dart';

final cycleRepositoryProvider = Provider((ref) => CycleRepository());
final pregnancyRepositoryProvider = Provider((ref) => PregnancyRepository());

final cycleStateProvider = StateNotifierProvider<CycleNotifier, CycleState>((ref) {
  final repo = ref.watch(cycleRepositoryProvider);
  final pregnancyRepo = ref.watch(pregnancyRepositoryProvider);
  return CycleNotifier(repo: repo, pregnancyRepo: pregnancyRepo);
});

class CycleNotifier extends StateNotifier<CycleState> {
  final CycleRepository _repo;
  final PregnancyRepository _pregnancyRepo;
  StreamSubscription<CycleRecord>? _subscription;

  CycleNotifier({
    required CycleRepository repo,
    required PregnancyRepository pregnancyRepo,
  })  : _repo = repo,
        _pregnancyRepo = pregnancyRepo,
        super(const CycleState.initial());

  void startListening() {
    _subscription?.cancel();
    _subscription = _repo.watchCurrentCycle().listen((record) {
      state = CycleState.loaded(record);
    }, onError: (err) {
      state = CycleState.error(err.toString());
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Future<void> saveRecord(CycleRecord record) async {
    try {
      final id = await _repo.saveCycleRecord(record);
      state = CycleState.loaded(record.copyWith(id: id));
    } catch (e) {
      state = CycleState.error(e.toString());
    }
  }

  Future<void> submitDailyCheckIn(DailyCheckIn checkIn) async {
    try {
      final saved = await _repo.saveDailyCheckIn(checkIn);
      
      final currentRecord = state.record;
      if (currentRecord != null) {
        final updatedCheckIns = Map<DateTime, DailyCheckIn>.from(currentRecord.dailyCheckIns);
        updatedCheckIns[saved.date] = saved;
        
        final updatedRecord = currentRecord.copyWith(dailyCheckIns: updatedCheckIns);
        state = CycleState.loaded(updatedRecord);
        
        // Trigger fertility update
        await _repo.updateFertilityPrediction(currentRecord.id);

        // Check for pregnancy transition
        await checkAndTransitionToPregnancy();
      }
    } catch (e) {
      state = CycleState.error(e.toString());
    }
  }

  /// Automatically checks if the current cycle should transition to pregnancy.
  /// If probability is > 70%, it flags the state for UI prompt.
  Future<void> checkAndTransitionToPregnancy() async {
    final record = state.record;
    if (record != null) {
      final shouldPrompt = await _pregnancyRepo.shouldTransition(record);
      if (shouldPrompt) {
        state = state.copyWith(showPregnancyPrompt: true);
      }
    }
  }

  /// Performs the actual transition to pregnancy.
  Future<void> performPregnancyTransition() async {
    final record = state.record;
    if (record != null) {
      try {
        await _pregnancyRepo.startPregnancyFromCycle(record);
        state = state.copyWith(showPregnancyPrompt: false);
        // The UI should listen to this change and navigate
      } catch (e) {
        state = CycleState.error(e.toString());
      }
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

enum CycleStatus { initial, loading, loaded, error }

class CycleState {
  final CycleStatus status;
  final CycleRecord? record;
  final String? error;
  final bool showPregnancyPrompt;

  const CycleState.initial()
      : status = CycleStatus.initial,
        record = null,
        error = null,
        showPregnancyPrompt = false;

  const CycleState.loading()
      : status = CycleStatus.loading,
        record = null,
        error = null,
        showPregnancyPrompt = false;

  const CycleState.loaded(this.record, {this.showPregnancyPrompt = false})
      : status = CycleStatus.loaded,
        error = null;

  const CycleState.error(this.error)
      : status = CycleStatus.error,
        record = null,
        showPregnancyPrompt = false;

  CycleState copyWith({
    CycleStatus? status,
    CycleRecord? record,
    String? error,
    bool? showPregnancyPrompt,
  }) {
    return CycleState._internal(
      status: status ?? this.status,
      record: record ?? this.record,
      error: error ?? this.error,
      showPregnancyPrompt: showPregnancyPrompt ?? this.showPregnancyPrompt,
    );
  }

  const CycleState._internal({
    required this.status,
    this.record,
    this.error,
    required this.showPregnancyPrompt,
  });
}
