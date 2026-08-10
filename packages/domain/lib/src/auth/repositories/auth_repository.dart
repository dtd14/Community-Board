import 'package:core/errors.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Stream<UserEntity?> get onAuthStateChanged;

  Future<Either<Failures, void>> signup({
    required String email,
    required String password,
    required String username,
  });

    Future<Either<Failures, void>> login({
    required String email,
    required String password,
  });

  Future<Either<Failures, void>> logout();
}