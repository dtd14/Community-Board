import 'dart:async';
import 'package:core/errors.dart';
import 'package:domain/auth.dart';
import 'package:fpdart/fpdart.dart';

import '../auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this._authRomoteDataSource});

  final AuthRemoteDataSource _authRomoteDataSource;

  @override
  Stream<UserEntity?> get onAuthStateChanged {
    final controller = StreamController<UserEntity?>();

    final subscription = _authRomoteDataSource.onAustateChanged.listen(
      (userModel) {
        controller.add(userModel);
      },
      onError: (error) {
        print('Auth Steam Error: $error');
        controller.add(null);
      },
    );
    controller.onCancel = () {
      subscription.cancel();
    };
    return controller.stream;
  }

  @override
  Future<Either<Failures, void>> signup({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await _authRomoteDataSource.signup(
        email: email,
        password: password,
        username: username,
      );
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, void>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _authRomoteDataSource.login(email: email, password: password);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, void>> logout() async {
    try {
      await _authRomoteDataSource.logout();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
