import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class UpdateCommentParams extends Equatable {
  const UpdateCommentParams({
    required this.commentId,
    required this.newContent,
  });

  final String commentId;
  final String newContent;

  @override
  List<Object> get props => [commentId, newContent];
}

class UpdateCommentUsecase implements UsecaseInterface {
  const UpdateCommentUsecase({required this._postRepository});

  final PostRepository _postRepository;

  @override
  Future<Either<Failures, CommentDisplay>> call(params) async {
    return await _postRepository.updateComment(
      commentId: params.commentId,
      newContent: params.newContent,
    );
  }
}
