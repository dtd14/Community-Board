import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/bus/global_event.dart';
import '../../../../../core/bus/global_event_bus.dart';
import '../../../../../core/utils/sealed_class_state.dart';

part 'post_form_event.dart';
part 'post_form_state.dart';

@injectable
class PostFormBloc extends Bloc<PostFormEvent, PostFormState> {
  PostFormBloc({
    required this._createPostUsecase,
    required this._uploadPostImageUsecase,
    required this._globalEventBus,
  }) : super(const PostFormInitial()) {
    on<PostSubmitted>(_onPostSubmitted);
  }
  final CreatePostUsecase _createPostUsecase;
  final UploadPostImageUsecase _uploadPostImageUsecase;
  final GlobalEventBus _globalEventBus;

  Future<void> _onPostSubmitted(
    PostSubmitted event,
    Emitter<PostFormState> emit,
  ) async {
    emit(const PostFormLoadInProgress());

    String? imageUrl;
    String? postId;

    if (event.imageFile != null) {
      final uploadResult = await _uploadPostImageUsecase(
        UploadPostImageParams(image: event.imageFile!, postId: null),
      );
      final success = uploadResult.fold(
        (failure) {
          emit(PostFormLoadFailure(failure: failure));
          return false;
        },
        (result) {
          postId = result.postId;
          imageUrl = result.imageUrl;
          return true;
        },
      );
      if (!success) return;
    }

    final createResult = await _createPostUsecase(
      CreatePostParams(
        title: event.title,
        content: event.content,
        postId: postId,
        imageUrl: imageUrl,
      ),
    );
    createResult.fold(
      (failure) {
        emit(PostFormLoadFailure(failure: failure));
      },
      (newPost) {
        _globalEventBus.add(PostCreatedDispatched(post: newPost));
        emit(PostFormLoadSuccess(data: newPost));
      },
    );
  }
}
