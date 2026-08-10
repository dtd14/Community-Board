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
}
