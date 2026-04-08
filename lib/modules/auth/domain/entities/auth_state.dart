import '../../../../core/error/failure.dart';
import 'app_session.dart';

enum AuthStatus { loading, unauthenticated, authenticated, reauthRequired }

class AuthState {
  const AuthState({required this.status, this.session, this.failure});

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.authenticated(AppSession session)
    : this(status: AuthStatus.authenticated, session: session);

  const AuthState.reauthRequired(Failure failure)
    : this(status: AuthStatus.reauthRequired, failure: failure);

  final AuthStatus status;
  final AppSession? session;
  final Failure? failure;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;
}
