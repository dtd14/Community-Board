import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class GetCommentsParams extends Equatable {
  const GetCommentsParams({
    required this.postId,
    required this.offset,
    this.limit = 10,
  });

  final String postId;
  final int offset;
  final int limit;

  @override
  List<Object> get props => [postId, offset, limit];
}

class GetCommentsUsecase
    implements UsecaseInterface<List<CommentDisplay>, GetCommentsParams> {
  const GetCommentsUsecase({required this._postRepository});

  final PostRepository _postRepository;

  @override
  Future<Either<Failures, List<CommentDisplay>>> call(
    GetCommentsParams params,
  ) async {
    return await _postRepository.getComments(
      postId: params.postId,
      offset: params.offset,
      limit: params.limit,
    );
  }
}
