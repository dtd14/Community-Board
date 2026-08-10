import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/post_display.dart';
import '../repositories/post_repository.dart';

class GetPostsParams extends Equatable {
  const GetPostsParams({required this.offset, this.limit = 10});

  final int offset;
  final int limit;

  @override
  List<Object> get props => [offset, limit];
}

class GetPostsUsecase
    implements UsecaseInterface<List<PostDisplay>, GetPostsParams> {
  const GetPostsUsecase({required this._postRepository});

  final PostRepository _postRepository;
  @override
  Future<Either<Failures, List<PostDisplay>>> call(
    GetPostsParams params,
  ) async {
    return await _postRepository.getPost(
      offset: params.offset,
      limit: params.limit,
    );
  }
}
