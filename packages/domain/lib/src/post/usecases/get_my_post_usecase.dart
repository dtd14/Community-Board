import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class GetMyPostParams extends Equatable {
  const GetMyPostParams({
    required this.userId,
    required this.offset,
    required this.limit,
  });

  final String userId;
  final int offset;
  final int limit;

  @override
  List<Object> get props => [userId, offset, limit];
}

class GetMyPostUsecase
    implements UsecaseInterface<List<PostDisplay>, GetMyPostParams> {
  const GetMyPostUsecase({required this._postRepository});

  final PostRepository _postRepository;

  @override
  Future<Either<Failures, List<PostDisplay>>> call(
    GetMyPostParams params,
  ) async {
    return await _postRepository.getMyPost(
      userId: params.userId,
      offset: params.offset,
      limit: params.limit,
    );
  }
}

