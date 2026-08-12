import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class DeletePostFolderUsecase implements UsecaseInterface {
  const DeletePostFolderUsecase({required this._postRepository});

  final PostRepository _postRepository;

  @override
  Future<Either<Failures, dynamic>> call(params) async {
    return await _postRepository.deletePostFolder(postId: params);
  }
}
