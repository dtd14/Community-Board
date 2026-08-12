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
  }) : super(const PostDetailState()) {
    on<PostDetailFetched>(_onPostDetailFetched);
    on<PostDetailLikeToggled>(_onPostDetailLikeToggled);
    on<_PostUpdatedFrombus>(_onPostUpdatedFrombus);
    on<PostDetailTransientFailureComsumed>(
      _onPostDetailTransientFailureComsumed,
    );
    on<PostDeleted>(_onPostDeleted);

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
  StreamSubscription<GlobalEvent>? _globalEventBusSubscription;
  bool get _isBusy =>
      state.status == PostDetailStatus.loading ||
      state.status == PostDetailStatus.submitting;

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
    if (_isBusy || state.post == null) return;

    final originalPost = state.post!;

    final optimisticPost = originalPost.copyWith(
      currentUserLiked: !originalPost.currentUserLiked,
      likesCount: originalPost.currentUserLiked
          ? originalPost.likesCount - 1
          : originalPost.likesCount + 1,
    );
    emit(
      state.copyWith(post: () => optimisticPost, transientFailure: () => null),
    );

    final result = await _toggleLikeUsecase(originalPost.postId);

    result.fold(
      (failure) => emit(
        state.copyWith(post: () => originalPost, transientFailure: () => null),
      ),
      (likeResult) {
        final authoritativePost = originalPost.copyWith(
          currentUserLiked: likeResult.liked,
          likesCount: likeResult.likesCount,
        );
        emit(state.copyWith(post: () => authoritativePost));

        _globalEventBus.add(PostUpdateDispatched(post: authoritativePost));
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
    if (state.status == PostDetailStatus.loaded) {
      emit(state.copyWith(post: () => event.post));
    }
  }

  @override
  Future<void> close() {
    _globalEventBusSubscription?.cancel();
    return super.close();
  }
}
