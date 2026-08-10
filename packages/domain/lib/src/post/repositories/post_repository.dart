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
    String? postId
  });
}
