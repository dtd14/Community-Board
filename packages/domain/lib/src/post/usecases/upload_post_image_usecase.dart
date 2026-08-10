import 'dart:io';

import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class UploadPostImageParams extends Equatable {
  const UploadPostImageParams({required this.image, this.postId});

  final File image;
  final String? postId;

  @override
  List<Object?> get props => [image, postId];
}

class UploadPostImageUsecase implements UsecaseInterface {
  UploadPostImageUsecase({required this._postRepository});

  final PostRepository _postRepository;
  @override
  Future<Either<Failures, dynamic>> call(params) async {
    return await _postRepository.uploadPostImage(image: params.image, postId: params.postId);
  }
}
