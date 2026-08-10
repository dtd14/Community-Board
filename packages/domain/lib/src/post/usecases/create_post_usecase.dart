import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class CreatePostParams {
  const CreatePostParams({
    this.postId,
    required this.title,
    required this.content,
    this.imageUrl,
  });

  final String? postId;
  final String title;
  final String content;
  final String? imageUrl;
}

class CreatePostUsecase implements UsecaseInterface {
  const CreatePostUsecase({required this._postRepository});

  final PostRepository _postRepository;
  @override
  Future<Either<Failures, dynamic>> call(params) async {
    return await _postRepository.createPost(
      title: params.title,
      imageUrl: params.imageUrl,
      postId: params.postId,
      content: params.content,
    );
  }
}
