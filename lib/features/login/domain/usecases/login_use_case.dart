import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

@lazySingleton
class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<String, UserEntity>> execute(String email, String password) async {
    try {
      final user = await repository.login(email, password);
      return Right(user);
    } catch (e) {
      return Left(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
