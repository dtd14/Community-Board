import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class ToggleLikeUsecase implements UsecaseInterface<LikeResult, String> {
  const ToggleLikeUsecase({required this._postRepository});

  final PostRepository _postRepository;

  @override
  Future<Either<Failures, LikeResult>> call(String params) async {
    return await _postRepository.toggleLike(postId: params);
  }
}
