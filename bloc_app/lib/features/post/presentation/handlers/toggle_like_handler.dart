import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bus/global_event.dart';
import '../../../../core/bus/global_event_bus.dart';

class ToggleLikeHandler<S> {
  const ToggleLikeHandler({
    required this._toggleLikeUseCase,
    required this._globalEventBus,
  });

  final ToggleLikeUsecase _toggleLikeUseCase;
  final GlobalEventBus _globalEventBus;

  Future<void> execute({
    required Emitter<S> emit,
    required S initialState,
    required PostDisplay postToToggle,
    required S Function() getLastestState,
    required List<PostDisplay> Function(S state) getPosts,
    required S Function(S state, List<PostDisplay> newPosts) copyWithPosts,
    required S Function(S state, Failures? failure) copyWithTransientFailure,
    required S Function(S data) successStateBuilder,
  }) async {
    final originalList = getPosts(initialState);
    final originalIndex = originalList.indexWhere(
      (p) => p.postId == postToToggle.postId,
    );
    if (originalIndex == -1) return;

    final originalPost = originalList[originalIndex];

    final optimisticPost = originalPost.copyWith(
      currentUserLiked: !originalPost.currentUserLiked,
      likesCount: originalPost.currentUserLiked
          ? originalPost.likesCount - 1
          : originalPost.likesCount + 1,
    );

    final optimisticList = List<PostDisplay>.from(originalList);
    optimisticList[originalIndex] = optimisticPost;

    final optimisticState = copyWithPosts(initialState, optimisticList);
    final stateWithoutFailure = copyWithTransientFailure(optimisticState, null);
    emit(successStateBuilder(stateWithoutFailure));

    final result = await _toggleLikeUseCase(postToToggle.postId);
    if (emit.isDone) return;

    final latestState = getLastestState();

    result.fold(
      (failure) {
        final rollbackList = getPosts(latestState)
            .map(
              (post) => post.postId == originalPost.postId
                  ? post.copyWith(
                      currentUserLiked: originalPost.currentUserLiked,
                      likesCount: originalPost.likesCount,
                    )
                  : post,
            )
            .toList();
        final rollbackState = copyWithPosts(latestState, rollbackList);
        final finalState = copyWithTransientFailure(rollbackState, failure);
        emit(successStateBuilder(finalState));
      },
      (likeResult) {
        final currentListAfterAwait = getPosts(latestState);
        final finalList = List<PostDisplay>.from(currentListAfterAwait);
        final finalIndex = finalList.indexWhere(
          (p) => p.postId == originalPost.postId,
        );

        if (finalIndex != -1) {
          final authoritativePost = finalList[finalIndex].copyWith(
            currentUserLiked: likeResult.liked,
            likesCount: likeResult.likesCount,
          );
          finalList[finalIndex] = authoritativePost;
          _globalEventBus.add(PostUpdateDispatched(post: authoritativePost));

          final finalState = copyWithPosts(latestState, finalList);

          emit(successStateBuilder(finalState));
        } else {
          emit(successStateBuilder(latestState));
        }
      },
    );
  }
}
