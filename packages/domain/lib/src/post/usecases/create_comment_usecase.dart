import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class CreateCommentParams extends Equatable {
  const CreateCommentParams({required this.postId, required this.content});

  final String postId;
  final String content;

  @override
  List<Object> get props => [postId, content];
}

class CreateCommentUsecase implements UsecaseInterface {
  const CreateCommentUsecase({required this._postRepository});

  final PostRepository _postRepository;

  @override
  Future<Either<Failures, CommentDisplay>> call(params) async {
    return await _postRepository.createComment(
      postId: params.postId,
      content: params.content,
    );
  }
}
