part of 'login_bloc.dart';

typedef LoginState = SealedClassState<Failures, void>;

typedef LoginInitial = SealedClassInitial<Failures, void>;
typedef LoginLoadInProgress = SealedClassLoadInProgress<Failures, void>;
typedef LoginLoadSuccess = SealedClassLoadSuccess<Failures, void>;
typedef LoginLoadFailure = SealedClassLoadFailure<Failures, void>;
