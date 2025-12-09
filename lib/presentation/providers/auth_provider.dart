import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart' as domain;
import 'repository_providers.dart';

// Auth state stream
final authStateProvider = StreamProvider<domain.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// Current user
final currentUserProvider = Provider<domain.User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// Auth notifier for sign in/sign up/sign out
class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.signIn(email, password);

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (user) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.signUp(email, password, displayName);

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (user) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signOut() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(
  () {
    return AuthNotifier();
  },
);
