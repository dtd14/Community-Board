import 'dart:io';

import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:fpdart/fpdart.dart';

import '../datasources/datasources.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl({required this._postRemoteDataSource});

  final PostRemoteDataSource _postRemoteDataSource;
  @override
  Future<Either<Failures, List<PostDisplay>>> getPost({
    required int offset,
    required int limit,
  }) async {
    try {
      final posts = await _postRemoteDataSource.getPost(
        offset: offset,
        limit: limit,
      );
      return Right(posts);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, PostDisplay>> createPost({
    String? postId,
    required String title,
    required String content,
    required String? imageUrl,
  }) async {
    try {
      final post = await _postRemoteDataSource.createPost(
        title: title,
        content: content,
        postId: postId,
        imageUrl: imageUrl,
      );
      return Right(post);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, ImageUploadResult>> uploadPostImage({
    required File image,
    String? postId,
  }) async {
    try {
      final imageUploadResult = await _postRemoteDataSource.uploadPostImage(
        image: image,
        postId: postId,
      );
      return Right(imageUploadResult);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on StorageServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, List<CommentDisplay>>> getComments({
    required String postId,
    required int offset,
    required int limit,
  }) async {
    try {
      final comments = await _postRemoteDataSource.getComments(
        postId: postId,
        offset: offset,
        limit: limit,
      );
      return Right(comments);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, PostDisplay>> getPostDetail({
    required String postId,
  }) async {
    try {
      final post = await _postRemoteDataSource.getPostDetail(postId: postId);
      return Right(post);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, LikeResult>> toggleLike({
    required String postId,
  }) async {
    try {
      final result = await _postRemoteDataSource.toggleLike(postId: postId);
      return Right(result);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, CommentDisplay>> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      final newComment = await _postRemoteDataSource.createComment(
        postId: postId,
        content: content,
      );
      return Right(newComment);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, void>> deteleComment({
    required String commentId,
  }) async {
    try {
      await _postRemoteDataSource.deleteComment(commentId: commentId);
      return const Right(null);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, CommentDisplay>> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    try {
      final updatedComment = await _postRemoteDataSource.updateComment(
        commentId: commentId,
        newContent: newContent,
      );
      return Right(updatedComment);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, void>> deletePost({required String postId}) async {
    try {
      await _postRemoteDataSource.deletePost(postId: postId);
      return const Right(null);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, void>> deletePostFolder({
    required String postId,
  }) async {
    try {
      await _postRemoteDataSource.deletePostFolder(postId: postId);
      return const Right(null);
    } catch (e) {
      print('deletePostFolder failed, but proceeding: $e');
      return const Right(null);
    }
  }

  @override
  Future<Either<Failures, PostDisplay>> updatePost({
    required String postId,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final updatedPost = await _postRemoteDataSource.updatePost(
        postId: postId,
        title: title,
        content: content,
        imageUrl: imageUrl,
      );
      return Right(updatedPost);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, List<PostDisplay>>> getMyPost({
    required String userId,
    required int offset,
    required int limit,
  }) async {
    try {
      final posts = await _postRemoteDataSource.getMyPosts(
        userId: userId,
        offset: offset,
        limit: limit,
      );
      return Right(posts);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
