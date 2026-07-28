sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final String nombre;
  final String tipo;
  final String userId;

  const AuthAuthenticated({
    required this.token,
    required this.nombre,
    required this.tipo,
    required this.userId,
  });
}

class AuthUnauthenticated extends AuthState {
  final String? error;
  const AuthUnauthenticated({this.error});
}
