import 'package:bloc/bloc.dart';
import 'package:core/errors.dart';
import 'package:domain/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/sealed_class_state.dart';

part 'signup_event.dart';
part 'signup_state.dart';

@injectable
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc({required this._signupUsecase}) : super(const SignupInitial()) {
    on<SignupRequested>(_onSignupRequested);
  }
  final SignupUsecase _signupUsecase;

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<SignupState> emit,
  ) async {
    emit(const SignupLoadInProgress());
    final result = await _signupUsecase(
      SignupParams(
        email: event.email,
        password: event.password,
        username: event.username,
      ),
    );
    result.fold(
      (failure) => emit(SignupState.failure(failure: failure)),
      (_) => emit(const SignupLoadSuccess(data: null)),
    );
  }
}
