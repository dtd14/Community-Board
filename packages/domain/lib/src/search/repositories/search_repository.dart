import 'package:core/errors.dart';
import 'package:fpdart/fpdart.dart';

import '../../../auth.dart';
import '../../../post.dart';

abstract interface class SearchRepository {
  Future<Either<Failures, List<PostDisplay>>> searchPosts({
    required String query,
  });

  Future<Either<Failures, List<UserEntity>>> searchUsers({
    required String query,
  });
}
