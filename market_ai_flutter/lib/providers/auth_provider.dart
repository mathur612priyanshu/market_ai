import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;

  AuthState({this.token, this.user, this.isLoading = false});

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? isLoading,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  void setSession(String token, Map<String, dynamic> user) {
    state = AuthState(token: token, user: user);
  }

  void updateUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
  }

  void clearSession() {
    state = AuthState();
  }

  void setLoading(bool val) {
    state = state.copyWith(isLoading: val);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
