import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Firebase failures
class FirebaseFailure extends Failure {
  const FirebaseFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

// Server failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
