import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../../../auth.dart';
import '../repositories/profile_repository.dart';

class GetProfileUsecase implements UsecaseInterface<UserEntity, String> {
  const GetProfileUsecase({required this._profileRepository});

  final ProfileRepository _profileRepository;

  @override
  Future<Either<Failures, UserEntity>> call(String params) async {
    return await _profileRepository.getProfile(params);
  }
}

