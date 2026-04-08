sealed class Failure implements Exception {
  const Failure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType(message: $message)';
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.cause, super.stackTrace});
}

final class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure(super.message, {super.cause, super.stackTrace});
}

final class PortalContractChangedFailure extends Failure {
  const PortalContractChangedFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

final class ParsingFailure extends Failure {
  const ParsingFailure(super.message, {super.cause, super.stackTrace});
}

final class BusinessFailure extends Failure {
  const BusinessFailure(super.message, {super.cause, super.stackTrace});
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause, super.stackTrace});
}
