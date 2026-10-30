import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/bus/global_event.dart';
import '../../../../../core/bus/global_event_bus.dart';

part 'post_detail_event.dart';
part 'post_detail_state.dart';

@injectable
class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  PostDetailBloc({
    required this._getPostDetailUsecase,
    required this._toggleLikeUsecase,
    required this._globalEventBus,
    required this._deletePostUsecase,
    required this._deletePostFolderUsecase,
    required this.acknowledgePostUsecase,
  }) : super(const PostDetailState()) {
    on<PostDetailFetched>(_onPostDetailFetched);
    on<PostDetailLikeToggled>(_onPostDetailLikeToggled);
    on<_PostUpdatedFrombus>(_onPostUpdatedFrombus);
    on<PostDetailTransientFailureComsumed>(
      _onPostDetailTransientFailureComsumed,
    );
    on<PostDeleted>(_onPostDeleted);
    on<PostDetailAcknowledged>(_onPostDetailAcknowledged);

    _globalEventBusSubscription = _globalEventBus.stream.listen((event) {
      if (event is PostUpdateDispatched) {
        if (state.post?.postId == event.post.postId) {
          add(_PostUpdatedFrombus(post: event.post));
        }
      }
    });
  }
  final GetPostDetailUsecase _getPostDetailUsecase;
  final ToggleLikeUsecase _toggleLikeUsecase;
  final GlobalEventBus _globalEventBus;
  final DeletePostUsecase _deletePostUsecase;
  final DeletePostFolderUsecase _deletePostFolderUsecase;
  final AcknowledgePostUsecase acknowledgePostUsecase;
  StreamSubscription<GlobalEvent>? _globalEventBusSubscription;
  bool get _isBusy =>
      state.status == PostDetailStatus.loading ||
      state.status == PostDetailStatus.submitting ||
      state.isAcknowledging ||
      state.isLiking;

  Future<void> _onPostDetailFetched(
    PostDetailFetched event,
    Emitter<PostDetailState> emit,
  ) async {
    if (_isBusy) return;

    emit(state.copyWith(status: PostDetailStatus.loading));

    final result = await _getPostDetailUsecase(event.postId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PostDetailStatus.failure,
          failure: () => failure,
        ),
      ),
      (post) => emit(
        state.copyWith(status: PostDetailStatus.loaded, post: () => post),
      ),
    );
  }

  Future<void> _onPostDetailLikeToggled(
    PostDetailLikeToggled event,
    Emitter<PostDetailState> emit,
  ) async {
    if (_isBusy ||
        state.post == null ||
        state.isLiking ||
        state.isAcknowledging) {
      return;
    }

    final originalPost = state.post!;

    final optimisticPost = originalPost.copyWith(
      currentUserLiked: !originalPost.currentUserLiked,
      likesCount: originalPost.currentUserLiked
          ? originalPost.likesCount - 1
          : originalPost.likesCount + 1,
    );
    emit(
      state.copyWith(
        post: () => optimisticPost,
        transientFailure: () => null,
        isLiking: true,
      ),
    );

    final result = await _toggleLikeUsecase(originalPost.postId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          post: () => state.post!.copyWith(
            likesCount: originalPost.likesCount,
            currentUserLiked: originalPost.currentUserLiked,
          ),
          transientFailure: () => failure,
          isLiking: false,
        ),
      ),
      (likeResult) {
        final authoritativePost = state.post!.copyWith(
          currentUserLiked: likeResult.liked,
          likesCount: likeResult.likesCount,
        );
        emit(state.copyWith(post: () => authoritativePost, isLiking: false));

        _globalEventBus.add(PostUpdateDispatched(post: authoritativePost));
      },
    );
  }

  Future<void> _onPostDetailAcknowledged(
    PostDetailAcknowledged event,
    Emitter<PostDetailState> emit,
  ) async {
    final post = state.post;
    if (_isBusy ||
        state.isAcknowledging ||
        state.isLiking ||
        post == null ||
        !post.requiresAcknowledgement ||
        post.currentUserAcknowledged) {
      return;
    }
    emit(state.copyWith(isAcknowledging: true, transientFailure: () => null));
    final result = await acknowledgePostUsecase(
      AcknowledgePostParams(
        postId: post.postId,
        contentVersion: post.contentVersion,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(isAcknowledging: false, transientFailure: () => failure),
      ),
      (updatedPost) {
        emit(state.copyWith(isAcknowledging: false, post: () => updatedPost));
        _globalEventBus.add(PostUpdateDispatched(post: updatedPost));
      },
    );
  }

  Future<void> _onPostDeleted(
    PostDeleted event,
    Emitter<PostDetailState> emit,
  ) async {
    if (_isBusy) return;

    final postToDelete = state.post!;

    emit(
      state.copyWith(
        status: PostDetailStatus.submitting,
        transientFailure: () => null,
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    final result = await _deletePostUsecase(postToDelete.postId);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: PostDetailStatus.loaded,
            transientFailure: () => failure,
          ),
        );
      },
      (_) {
        if (postToDelete.imageUrl != null) {
          _deletePostFolderUsecase(postToDelete.postId);
        }
        _globalEventBus.add(PostDeletedDispatched(postId: postToDelete.postId));

        emit(
          state.copyWith(
            status: PostDetailStatus.loaded,
            deletionSuccess: true,
          ),
        );
      },
    );
  }

  void _onPostDetailTransientFailureComsumed(
    PostDetailTransientFailureComsumed event,
    Emitter<PostDetailState> emit,
  ) {
    emit(state.copyWith(transientFailure: () => null));
  }

  void _onPostUpdatedFrombus(
    _PostUpdatedFrombus event,
    Emitter<PostDetailState> emit,
  ) {
    if (state.status == PostDetailStatus.loaded &&
        event.post.contentVersion >= (state.post?.contentVersion ?? 0)) {
      emit(state.copyWith(post: () => event.post));
    }
  }

  @override
  Future<void> close() {
    _globalEventBusSubscription?.cancel();
    return super.close();
  }
}
