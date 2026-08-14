part of 'profile_bloc.dart';

typedef ProfileState = SealedClassState<Failures, UserEntity>;

typedef ProfileInitial = SealedClassInitial<Failures, UserEntity>;
typedef ProfileLoadInProgress = SealedClassLoadInProgress<Failures, UserEntity>;
typedef ProfileLoadSuccess = SealedClassLoadSuccess<Failures, UserEntity>;
typedef ProfileLoadFailure = SealedClassLoadFailure<Failures, UserEntity>;