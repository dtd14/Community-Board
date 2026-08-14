import 'dart:io';

import 'package:core/errors.dart';
import 'package:fpdart/fpdart.dart';

import '../../../auth.dart';

abstract interface class ProfileRepository {
  Future<Either<Failures, UserEntity>> getProfile(String userId);

  Future<Either<Failures, UserEntity>> updateProfile({
    required String username,
    String? avatarUrl,
  });

  Future<Either<Failures, String>> uploadAvatar({
    required String userId,
    required File image,
  });

  Future<Either<Failures, void>> deleteAvatar(String avatarUrl);
}
