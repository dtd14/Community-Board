part of 'post_form_bloc.dart';

typedef PostFormState = SealedClassState<Failures, PostDisplay>;

typedef PostFormInitial = SealedClassInitial<Failures, PostDisplay>;
typedef PostFormLoadInProgress =
    SealedClassLoadInProgress<Failures, PostDisplay>;
typedef PostFormLoadSuccess = SealedClassLoadSuccess<Failures, PostDisplay>;
typedef PostFormLoadFailure = SealedClassLoadFailure<Failures, PostDisplay>;
