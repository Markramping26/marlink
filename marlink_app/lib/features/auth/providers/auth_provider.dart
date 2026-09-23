import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/models/user_model.dart';
import '../domain/models/user_profile_model.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final hasToken = await _repository.hasValidToken();
      if (!hasToken) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final user = await _repository.getProfile();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String login, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(login: login, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.friendlyErrorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed. Please verify your credentials.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.register(
        name: name,
        username: username,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.friendlyErrorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registration failed. Please check form inputs.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateLocationSharing({
    required String status,
    int? durationMinutes,
  }) async {
    if (state.user == null) return;
    final prevUser = state.user!;
    final optProfile = (prevUser.profile ?? UserProfileModel()).copyWith(
      sharingStatus: status,
      isSharingActive: status == 'on',
    );
    state = state.copyWith(user: prevUser.copyWith(profile: optProfile));

    try {
      final updatedUser = await _repository.updateProfile({
        'sharing_status': status,
        if (durationMinutes != null) 'sharing_duration_minutes': durationMinutes,
      });
      state = state.copyWith(user: updatedUser);
    } catch (_) {
      // Keep the optimistic state so user's explicit preference stays active
    }
  }

  Future<void> updateProfileSettings({
    bool? showSpeed,
    bool? showBattery,
    String? bio,
  }) async {
    if (state.user == null) return;
    final prevUser = state.user!;
    final optProfile = (prevUser.profile ?? UserProfileModel()).copyWith(
      showSpeed: showSpeed,
      showBattery: showBattery,
      bio: bio,
    );
    state = state.copyWith(user: prevUser.copyWith(profile: optProfile));

    try {
      final Map<String, dynamic> data = {};
      if (showSpeed != null) data['show_speed'] = showSpeed;
      if (showBattery != null) data['show_battery'] = showBattery;
      if (bio != null) data['bio'] = bio;

      final updatedUser = await _repository.updateProfile(data);
      state = state.copyWith(user: updatedUser);
    } catch (_) {
      state = state.copyWith(user: prevUser);
    }
  }

  Future<bool> uploadAvatar(dynamic imageFile) async {
    if (state.user == null) return false;
    try {
      final updatedUser = await _repository.uploadAvatar(imageFile);
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return null; // Success
    } on ApiException catch (e) {
      return e.friendlyErrorMessage;
    } catch (e) {
      return 'Failed to change password. Please check current password.';
    }
  }

  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}
