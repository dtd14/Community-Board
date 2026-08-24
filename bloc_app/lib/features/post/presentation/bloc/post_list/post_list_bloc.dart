import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/bus/global_event.dart';
import '../../../../../core/bus/global_event_bus.dart';
import '../../handlers/pagination_handler.dart';
import '../../handlers/toggle_like_handler.dart';

part 'post_list_event.dart';
part 'post_list_state.dart';

const _pageSize = 5;

@injectable
class PostListBloc extends Bloc<PostListEvent, PostListState> {
  PostListBloc({
    required this._getPostsUsecase,
    required this._globalEventBus,
    required this._toggleLikeUsecase,
  }) : super(const PostListState()) {
    on<PostListFetched>(_onPostListFetched);
    on<PostListNextPageFetched>(_onPostListNextPageFetched);
    on<PostListRefreshed>(_onPostListRefreshed);
    on<PostListTransientFailureConsumed>(_onPostListTransientFailureConsumed);
    on<_GlobalEventReceived>(_onGlobalEventReceived);
    on<PostLikeToggled>(_onPostLikeToggled);
    on<_PostListRefillRequested>(_onPostListRefillRequested);
    on<PostListNewPostPrepended>(_onPostListNewPostPrepended);
    on<PostListScrollToTop>(_onPostListScrollToTop);
    on<PostListEventScrollConsumed>(_onPostListEventScrollConsumed);
    on<PostListResetRequested>((event, emit) => emit(const PostListState()),);

    _globalEventBusSubscription = _globalEventBus.stream.listen((event) {
      add(_GlobalEventReceived(event: event));
    });

    _paginationHandler = PaginationHandler();
    _toggleLikeHandler = ToggleLikeHandler(
      toggleLikeUseCase: _toggleLikeUsecase,
      globalEventBus: _globalEventBus,
    );
  }

  final GetPostsUsecase _getPostsUsecase;
  final GlobalEventBus _globalEventBus;
  final ToggleLikeUsecase _toggleLikeUsecase;
  StreamSubscription<GlobalEvent>? _globalEventBusSubscription;

  late final PaginationHandler<PostListState> _paginationHandler;
  late final ToggleLikeHandler<PostListState> _toggleLikeHandler;

  bool get _isBusy =>
      state.status == PostListStatus.loading ||
      state.status == PostListStatus.refreshing ||
      state.status == PostListStatus.refilling ||
      state.status == PostListStatus.fetchingNextPage;
  Future<void> _onPostListFetched(
    PostListFetched event,
    Emitter<PostListState> emit,
  ) async {
    if (_isBusy) return;

    emit(state.copyWith(status: PostListStatus.loading));

    final result = await _getPostsUsecase(
      const GetPostsParams(offset: 0, limit: _pageSize),
    );
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: PostListStatus.failure,
            failure: () => failure,
          ),
        );
      },
      (posts) {
        emit(
          state.copyWith(
            status: PostListStatus.loaded,
            posts: posts,
            hasReachedMax: posts.length < _pageSize,
          ),
        );
      },
    );
  }

  Future<void> _onPostListNextPageFetched(
    PostListNextPageFetched event,
    Emitter<PostListState> emit,
  ) async {
    if (_isBusy || state.hasReachedMax) return;

    emit(state.copyWith(status: PostListStatus.fetchingNextPage));

    final newState = await _paginationHandler.fetchNextPage(
      currentState: state,
      fetchPostsStrategy: ({required int offset, required int limit}) {
        return _getPostsUsecase(GetPostsParams(offset: offset, limit: limit));
      },
      pagesize: _pageSize,
      getLastestState: () => state,
      getPosts: (state) => state.posts,
      copyWithPosts: (state, newPosts) => state.copyWith(posts: newPosts),
      copyWithHasReachedMax: (state, hasReachedMax) =>
          state.copyWith(hasReachedMax: hasReachedMax),
      copyWithTransientFailure: (state, failure) =>
          state.copyWith(transientFailure: () => failure),
    );

    emit(newState.copyWith(status: PostListStatus.loaded));
  }

  // Future<void> _onPostListNextPageFetched(
  //   PostListNextPageFetched event,
  //   Emitter<PostListState> emit,
  // ) async {
  //   if (_isBusy || state.hasReachedMax) return;

  //   emit(state.copyWith(status: PostListStatus.fetchingNextPage));

  //   await Future.delayed(const Duration(seconds: 1));

  //   final result = await _getPostsUsecase(
  //     GetPostsParams(offset: state.posts.length, limit: _pageSize),
  //   );

  //   result.fold(
  //     (failure) => emit(
  //       state.copyWith(
  //         status: PostListStatus.loaded,
  //         transientFailure: () => failure,
  //       ),
  //     ),
  //     (newPosts) {
  //       emit(
  //         state.copyWith(
  //           status: PostListStatus.loaded,
  //           posts: [...state.posts, ...newPosts],
  //           hasReachedMax: newPosts.length < _pageSize,
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> _onPostListRefreshed(
    PostListRefreshed event,
    Emitter<PostListState> emit,
  ) async {
    if (_isBusy) return;
    emit(state.copyWith(status: PostListStatus.refreshing));
    final result = await _getPostsUsecase(
      const GetPostsParams(offset: 0, limit: _pageSize),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PostListStatus.loaded,
          transientFailure: () => failure,
        ),
      ),
      (posts) {
        emit(
          state.copyWith(
            status: PostListStatus.loaded,
            posts: posts,
            hasReachedMax: posts.length < _pageSize,
          ),
        );
      },
    );
  }

  void _onPostListTransientFailureConsumed(
    PostListTransientFailureConsumed event,
    Emitter<PostListState> emit,
  ) {
    emit(state.copyWith(transientFailure: () => null));
  }

  void _onGlobalEventReceived(
    _GlobalEventReceived event,
    Emitter<PostListState> emit,
  ) {
    if (state.status != PostListStatus.fetchingNextPage && _isBusy) return;

    switch (event.event) {
      case PostCreatedDispatched(post: final newPost):
        final currentPosts = state.posts;
        emit(state.copyWith(posts: [newPost, ...currentPosts]));
      case PostUpdateDispatched(post: final updatedPost):
        final currentPosts = state.posts;
        final newPosts = currentPosts
            .map((e) => e.postId == updatedPost.postId ? updatedPost : e)
            .toList();
        emit(state.copyWith(posts: newPosts));
      case PostDeletedDispatched(postId: final deletedPostId):
        final currentPosts = state.posts;
        final newPosts = currentPosts
            .where((p) => p.postId != deletedPostId)
            .toList();
        emit(state.copyWith(posts: newPosts));

        add(_PostListRefillRequested());
      case ProfileUpdatedDispatched(profile: final updatedProfile):
        final currentPosts = state.posts;
        final newPosts = currentPosts.map((post) {
          if (post.authorId == updatedProfile.id) {
            return post.copyWith(
              authorUsername: updatedProfile.username,
              authorAvatarUrl: () => updatedProfile.avatarUrl,
            );
          }
          return post;
        }).toList();
        emit(state.copyWith(posts: newPosts));
    }
  }

  @override
  Future<void> close() {
    _globalEventBusSubscription?.cancel();
    return super.close();
  }

  Future<void> _onPostLikeToggled(
    PostLikeToggled event,
    Emitter<PostListState> emit,
  ) async {
    if (_isBusy) return;

    await _toggleLikeHandler.execute(
      emit: emit,
      initialState: state,
      postToToggle: event.post,
      getLastestState: () => state,
      getPosts: (state) => state.posts,
      copyWithPosts: (state, newPosts) => state.copyWith(posts: newPosts),
      copyWithTransientFailure: (state, failure) =>
          state.copyWith(transientFailure: () => failure),
      successStateBuilder: (state) =>
          state.copyWith(status: PostListStatus.loaded),
    );
  }

  // Future<void> _onPostLikeToggled(
  //   PostLikeToggled event,
  //   Emitter<PostListState> emit,
  // ) async {
  //   if (_isBusy) return;

  //   final originalList = state.posts;
  //   final originalPost = event.post;
  //   final originalIndex = originalList.indexWhere(
  //     (p) => p.postId == originalPost.postId,
  //   );
  //   if (originalIndex == -1) return;

  //   final optimisticPost = originalPost.copyWith(
  //     currentUserLiked: !originalPost.currentUserLiked,
  //     likesCount: originalPost.currentUserLiked
  //         ? originalPost.likesCount - 1
  //         : originalPost.likesCount + 1,
  //   );
  //   final optimisticList = List<PostDisplay>.from(originalList);
  //   optimisticList[originalIndex] = optimisticPost;

  //   emit(state.copyWith(posts: optimisticList, transientFailure: () => null));

  //   final result = await _toggleLikeUsecase(originalPost.postId);

  //   result.fold(
  //     (failure) {
  //       emit(
  //         state.copyWith(posts: originalList, transientFailure: () => failure),
  //       );
  //     },
  //     (likeResult) {
  //       final authoritativePost = originalPost.copyWith(
  //         currentUserLiked: likeResult.liked,
  //         likesCount: likeResult.likesCount,
  //       );
  //       final finalList = List<PostDisplay>.from(state.posts);
  //       final finalIndex = finalList.indexWhere(
  //         (p) => p.postId == authoritativePost.postId,
  //       );

  //       if (finalIndex != -1) {
  //         finalList[finalIndex] = authoritativePost;

  //         _globalEventBus.add(PostUpdateDispatched(post: authoritativePost));

  //         emit(state.copyWith(posts: finalList));
  //       } else {
  //         emit(state);
  //       }
  //     },
  //   );
  // }

  Future<void> _onPostListRefillRequested(
    _PostListRefillRequested event,
    Emitter<PostListState> emit,
  ) async {
    if (_isBusy || state.hasReachedMax) return;

    emit(state.copyWith(status: PostListStatus.refilling));

    final newState = await _paginationHandler.fetchOneToRefill(
      currentState: state,
      fetchPostsStrategy: ({required int offset, required int limit}) {
        return _getPostsUsecase(GetPostsParams(offset: offset, limit: limit));
      },
      getLastestState: () => state,
      getPosts: (state) => state.posts,
      copyWithPosts: (state, newPosts) => state.copyWith(posts: newPosts),
      copyWithHasReachedMax: (state, hasReachedMax) =>
          state.copyWith(hasReachedMax: hasReachedMax),
      copyWithTransientFailure: (state, failure) =>
          state.copyWith(transientFailure: () => failure),
    );

    emit(newState.copyWith(status: PostListStatus.loaded));
  }

  // Future<void> _onPostListRefillRequested(
  //   _PostListRefillRequested event,
  //   Emitter<PostListState> emit,
  // ) async {
  //   if (_isBusy || state.hasReachedMax) return;

  //   emit(state.copyWith(status: PostListStatus.refilling));

  //   final result = await _getPostsUsecase(
  //     GetPostsParams(offset: state.posts.length, limit: 1),
  //   );

  //   result.fold(
  //     (failure) {
  //       emit(
  //         state.copyWith(
  //           status: PostListStatus.loaded,
  //           transientFailure: () => failure,
  //         ),
  //       );
  //     },
  //     (newPost) {
  //       if (newPost.isNotEmpty) {
  //         emit(
  //           state.copyWith(
  //             status: PostListStatus.loaded,
  //             posts: [...state.posts, ...newPost],
  //           ),
  //         );
  //       } else {
  //         emit(
  //           state.copyWith(status: PostListStatus.loaded, hasReachedMax: true),
  //         );
  //       }
  //     },
  //   );
  // }

  void _onPostListNewPostPrepended(
    PostListNewPostPrepended event,
    Emitter<PostListState> emit,
  ) {
    if (state.posts.any((p) => p.postId == event.post.postId)) return;

    final updatedPosts = [event.post, ...state.posts];
    emit(state.copyWith(posts: updatedPosts));
  }

  void _onPostListScrollToTop(
    PostListScrollToTop event,
    Emitter<PostListState> emit,
  ) {
    emit(
      state.copyWith(
        scrollToTopEventId: () => DateTime.now().microsecondsSinceEpoch,
      ),
    );
  }

  void _onPostListEventScrollConsumed(
    PostListEventScrollConsumed event,
    Emitter<PostListState> emit,
  ) {
    emit(state.copyWith(scrollToTopEventId: () => null));
  }
}
