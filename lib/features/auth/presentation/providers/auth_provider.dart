import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oummi3/core/services/user_repository.dart';
import 'package:oummi3/shared/models/user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(userRepositoryProvider).authStateChanges;
});

final userProfileProvider = StateNotifierProvider<UserNotifier, AsyncValue<OumiUser?>>((ref) {
  return UserNotifier(ref.watch(userRepositoryProvider));
});

class UserNotifier extends StateNotifier<AsyncValue<OumiUser?>> {
  final UserRepository _repo;

  UserNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _repo.userProfileStream.listen((profile) {
      state = AsyncValue.data(profile);
    });
  }

  Future<void> reloadProfile() async {
    final user = _repo.firebaseUser;
    if (user != null) {
      state = const AsyncValue.loading();
      final profile = await _repo.getUserProfile(user.uid);
      state = AsyncValue.data(profile);
    }
  }

  Future<void> setUserRole(OumiRole role) async {
    state = const AsyncValue.loading();
    try {
      await _repo.setUserRole(role.name);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> switchRole(OumiRole role) async {
    state = const AsyncValue.loading();
    try {
      await _repo.switchRole(role.name);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> completeOnboarding(OumiUser profile) async {
    state = const AsyncValue.loading();
    try {
      await _repo.completeOnboarding(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }
}

/// Listens to auth and profile changes to trigger GoRouter redirects
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (prev, next) {
      notifyListeners();
    });
    _ref.listen(userProfileProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = ChangeNotifierProvider((ref) => RouterNotifier(ref));

// 🔙 Backward compatibility provider (if needed)
final authRepositoryProvider = Provider((ref) => ref.watch(userRepositoryProvider));
