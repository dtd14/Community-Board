import 'dart:io';

import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../repositories/profile_repository.dart';

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
    required this.userId,
    required this.username,
    this.originalAvatarUrl,
    this.newAvatarFile,
    this.avatarWasRemoved = false,
  });

  final String userId;
  final String username;
  final String? originalAvatarUrl;
  final File? newAvatarFile;
  final bool avatarWasRemoved;

  @override
  List<Object?> get props => [
    userId,
    username,
    originalAvatarUrl,
    newAvatarFile,
    avatarWasRemoved
  ];
}

class UpdateProfileUsecase implements UsecaseInterface {
  const UpdateProfileUsecase({required this._profileRepository});

  final ProfileRepository _profileRepository;

  @override
  Future<Either<Failures, dynamic>> call(params) async {
    try {
      String? finalAvatarUrl = params.originalAvatarUrl;

      if (params.newAvatarFile != null) {
        if (params.originalAvatarUrl != null) {
          await _profileRepository.deleteAvatar(params.originalAvatarUrl!);
        }
        final uploadResult = await _profileRepository.uploadAvatar(
          userId: params.userId,
          image: params.newAvatarFile,
        );
        finalAvatarUrl = uploadResult.getOrElse((l) => throw l);
      } else if (params.avatarWasRemoved) {
        if (params.originalAvatarUrl != null) {
          await _profileRepository.deleteAvatar(params.originalAvatarUrl!);
        }
        finalAvatarUrl = null;
      }
      return await _profileRepository.updateProfile(username: params.username, avatarUrl: finalAvatarUrl);
    } on Failures catch (e) {
      return left(e);
    }
  }
}
