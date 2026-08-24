import 'package:core/errors.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

abstract interface class RealtimeRepository {
  Stream<Either<Failures, PostDisplay>> get newPostStream;

  Future<void> disconnect();
}
