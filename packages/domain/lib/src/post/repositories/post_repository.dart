import 'dart:io';

import 'package:core/errors.dart';
import 'package:fpdart/fpdart.dart';

import '../post.dart';

abstract interface class PostRepository {
  Future<Either<Failures, List<PostDisplay>>> getPost({
    required int offset,
    required int limit,
  });
  Future<Either<Failures, PostDisplay>> createPost({
    String? postId,
    required String title,
    required String content,
    required String? imageUrl,
  });
  Future<Either<Failures, ImageUploadResult>> uploadPostImage({
    required File image,
    String? postId,
  });
  Future<Either<Failures, PostDisplay>> getPostDetail({required String postId});

  Future<Either<Failures, List<CommentDisplay>>> getComments({
    required String postId,
    required int offset,
    required int limit,
  });

  Future<Either<Failures, LikeResult>> toggleLike({required String postId});

  Future<Either<Failures, CommentDisplay>> createComment({
    required String postId,
    required String content,
  });

  Future<Either<Failures, void>> deteleComment({required String commentId});

  Future<Either<Failures, CommentDisplay>> updateComment({
    required String commentId,
    required String newContent,
  });

  Future<Either<Failures, void>> deletePost({required String postId});

  Future<Either<Failures, void>> deletePostFolder({required String postId});

  Future<Either<Failures, PostDisplay>> updatePost({
    required String postId,
    required String title,
    required String content,
    String? imageUrl,
  });

  Future<Either<Failures, List<PostDisplay>>> getMyPost({
    required String userId,
    required int offset,
    required int limit,
  });

  
}
