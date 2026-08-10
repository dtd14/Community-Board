part of 'signup_bloc.dart';

typedef SignupState = SealedClassState<Failures, void>;

typedef SignupInitial = SealedClassInitial<Failures, void>;
typedef SignupLoadInProgress = SealedClassLoadInProgress<Failures, void>;
typedef SignupLoadSuccess = SealedClassLoadSuccess<Failures, void>;
typedef SignupLoadFailure = SealedClassLoadFailure<Failures, void>;
