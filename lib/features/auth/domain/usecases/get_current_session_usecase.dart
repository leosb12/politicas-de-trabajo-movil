import '../entities/authenticated_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentSessionUseCase {
  GetCurrentSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthenticatedUser?> call() {
    return _repository.getPersistedSession();
  }
}
