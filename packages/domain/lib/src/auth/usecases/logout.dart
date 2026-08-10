import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../repositories/auth_repository.dart';

class LogoutUsecase implements UsecaseInterface<void, Noparams>{
  const LogoutUsecase({required this._authRepository});
  final AuthRepository _authRepository;

  @override
  Future<Either<Failures, dynamic>> call(Noparams params) async {
    return await _authRepository.logout();
  }
}