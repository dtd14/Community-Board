import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class GetPostDetailUsecase implements UsecaseInterface<PostDisplay, String> {
  const GetPostDetailUsecase({required this._postRepository});

  final PostRepository _postRepository;

  @override
  Future<Either<Failures, PostDisplay>> call(String params) async {
    return await _postRepository.getPostDetail(postId: params);
  }
}
