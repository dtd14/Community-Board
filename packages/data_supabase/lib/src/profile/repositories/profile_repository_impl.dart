import 'dart:io';

import 'package:core/errors.dart';
import 'package:domain/auth.dart';
import 'package:domain/profile.dart';
import 'package:fpdart/fpdart.dart';

import '../datasources/datasources.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this._profileRemoteDataSource});

  final ProfileRemoteDataSource _profileRemoteDataSource;

  @override
  Future<Either<Failures, UserEntity>> getProfile(String userId) async {
    try {
      final profile = await _profileRemoteDataSource.getProfile(userId);
      return Right(profile);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, String>> uploadAvatar({
    required String userId,
    required File image,
  }) async {
    try {
      final url = await _profileRemoteDataSource.uploadAvatar(
        image: image,
        userId: userId,
      );
      return Right(url);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on StorageServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, UserEntity>> updateProfile({
    required String username,
    String? avatarUrl,
  }) async {
    try {
      final updateProfile = await _profileRemoteDataSource.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
      );
      return Right(updateProfile);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, void>> deleteAvatar(String avatarUrl) async {
    try {
      await _profileRemoteDataSource.deleteAvatar(avatarUrl);
      return const Right(null);
    } catch (e) {
      return const Right(null);
    }
  }
}
