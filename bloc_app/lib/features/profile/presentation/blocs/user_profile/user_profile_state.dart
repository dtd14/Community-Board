part of 'user_profile_bloc.dart';

typedef UserProfileState = SealedClassState<Failures, UserEntity>;

typedef UserProfileInitial = SealedClassInitial<Failures, UserEntity>;
typedef UserProfileLoadInProgress =
    SealedClassLoadInProgress<Failures, UserEntity>;
typedef UserProfileLoadSuccess = SealedClassLoadSuccess<Failures, UserEntity>;
typedef UserProfileLoadFailure = SealedClassLoadFailure<Failures, UserEntity>;