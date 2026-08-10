import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';

abstract interface class UsecaseInterface<ReturnType, ParamsType> {
  Future<Either<Failures, ReturnType>> call(ParamsType params);
}

class Noparams extends Equatable{
  const Noparams();
  
  @override
  List<Object?> get props => [];
}