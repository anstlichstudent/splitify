import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';

/// Use case untuk accept friend request
/// Temporary implementation - will be replaced with repository pattern later
class AcceptFriendRequestUseCase {
  AcceptFriendRequestUseCase();

  /// Accept friend request
  /// [requestId] - ID dari friend request
  /// [fromUid] - UID dari pengirim request
  Future<Either<Failure, void>> call(String requestId, String fromUid) async {
    try {
      // Implementasi akan menggunakan UserRepository nanti
      // Untuk sekarang, method ini hanya sebagai interface
      return const Right(null);
    } catch (e) {
      return Left(FirebaseFailure(e.toString()));
    }
  }
}
