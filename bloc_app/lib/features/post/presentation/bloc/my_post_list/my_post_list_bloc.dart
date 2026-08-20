import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/post.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/bus/global_event.dart';
import '../../../../../core/bus/global_event_bus.dart';
import '../../handlers/pagination_handler.dart';
import '../../handlers/toggle_like_handler.dart';
import '../post_list/post_list_bloc.dart';

part 'my_post_list_event.dart';
part 'my_post_list_state.dart';

const _pageSize = 5;

@injectable
class MyPostListBloc extends Bloc<MyPostListEvent, MyPostListState> {
  MyPostListBloc({
    required this._getMyPostUsecase,
    required this._toggleLikeUsecase,
    required this._globalEventBus,
  }) : super(const MyPostListState()) {
    on<MyPostListFetched>(_onMyPostListFetched);
    on<MyPostListNextPageFetched>(_onMyPostListNextPageFetched);
    on<MyPostListRefreshed>(_onMyPostListRefreshed);
    on<MyPostLikeToggled>(_onMyPostLikeToggled);
    on<MyPostListTransientFailureConsumed>(
      _onMyPostListTransientFailureConsumed,
    );
    on<_MyPostListRefillRequested>(_onMyPostListRefillRequested);
    on<_GlobalEventReceived>(_onGlobalEventReceived);

    _globalEventBusSubscription = _globalEventBus.stream.listen((event) {
      add(_GlobalEventReceived(event: event));
    });

    _paginationHandler = PaginationHandler();
    _toggleLikeHandler = ToggleLikeHandler(
      toggleLikeUseCase: _toggleLikeUsecase,
      globalEventBus: _globalEventBus,
    );
  }

  final GetMyPostUsecase _getMyPostUsecase;
  final ToggleLikeUsecase _toggleLikeUsecase;
  final GlobalEventBus _globalEventBus;

  late final PaginationHandler<MyPostListState> _paginationHandler;
  late final ToggleLikeHandler<MyPostListState> _toggleLikeHandler;

  StreamSubscription<GlobalEvent>? _globalEventBusSubscription;

  String? _userId;

  bool get _isBusy =>
      state.status == MyPostListStatus.loading ||
      state.status == MyPostListStatus.fetchingNextPage ||
      state.status == MyPostListStatus.refilling ||
      state.status == MyPostListStatus.refreshing;

  Future<void> _onMyPostListFetched(
    MyPostListFetched event,
    Emitter<MyPostListState> emit,
  ) async {
    if (_isBusy) return;
    _userId = event.userId;

    emit(state.copyWith(status: MyPostListStatus.loading));

    final result = await _getMyPostUsecase(
      GetMyPostParams(userId: event.userId, offset: 0, limit: _pageSize),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MyPostListStatus.failure,
          failure: () => failure,
        ),
      ),
      (posts) => emit(
        state.copyWith(
          status: MyPostListStatus.loaded,
          posts: posts,
          hasReachedMax: posts.length < _pageSize,
        ),
      ),
    );
  }

  Future<void> _onMyPostListNextPageFetched(
    MyPostListNextPageFetched event,
    Emitter<MyPostListState> emit,
  ) async {
    if (_isBusy || state.hasReachedMax) return;
    _userId = event.userId;

    emit(state.copyWith(status: MyPostListStatus.fetchingNextPage));

    final newState = await _paginationHandler.fetchNextPage(
      currentState: state,
      fetchPostsStrategy: ({required int offset, required int limit}) {
        return _getMyPostUsecase(
          GetMyPostParams(userId: event.userId, offset: offset, limit: limit),
        );
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

  // Future<void> _onMyPostListNextPageFetched(
  //   MyPostListNextPageFetched event,
  //   Emitter<MyPostListState> emit,
  // ) async {
  //   if (_isBusy || state.hasReachedMax) return;
  //   _userId = event.userId;

  //   emit(state.copyWith(status: MyPostListStatus.fetchingNextPage));

  //   await Future.delayed(const Duration(seconds: 1));

  //   final result = await _getMyPostUsecase(
  //     GetMyPostParams(
  //       userId: event.userId,
  //       offset: state.posts.length,
  //       limit: _pageSize,
  //     ),
  //   );

  //   result.fold(
  //     (failure) => emit(
  //       state.copyWith(
  //         status: MyPostListStatus.loaded,
  //         transientFailure: () => failure,
  //       ),
  //     ),
  //     (newPosts) => emit(
  //       state.copyWith(
  //         status: MyPostListStatus.loaded,
  //         posts: state.posts + newPosts,
  //         hasReachedMax: newPosts.length < _pageSize,
  //       ),
  //     ),
  //   );
  // }

  Future<void> _onMyPostListRefreshed(
    MyPostListRefreshed event,
    Emitter<MyPostListState> emit,
  ) async {
    if (_isBusy) return;
    _userId = event.userId;

    emit(state.copyWith(status: MyPostListStatus.refreshing));

    final result = await _getMyPostUsecase(
      GetMyPostParams(userId: event.userId, offset: 0, limit: _pageSize),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MyPostListStatus.loaded,
          transientFailure: () => failure,
        ),
      ),
      (posts) => emit(
        state.copyWith(
          status: MyPostListStatus.loaded,
          posts: posts,
          hasReachedMax: posts.length < _pageSize,
        ),
      ),
    );
  }

  void _onMyPostListTransientFailureConsumed(
    MyPostListTransientFailureConsumed event,
    Emitter<MyPostListState> emit,
  ) {
    emit(state.copyWith(transientFailure: () => null));
  }

  Future<void> _onMyPostLikeToggled(
    MyPostLikeToggled event,
    Emitter<MyPostListState> emit,
  ) async {
    if (_isBusy) return;

    await _toggleLikeHandler.execute(
      emit: emit,
      initialState: state,
      postToToggle: event.post,
      getLastestState: () => state,
      getPosts: (state) => state.posts,
      copyWithPosts: (state, newPosts) => state.copyWith(posts: newPosts),
      copyWithTransientFailure: (state, failure) => state.copyWith(transientFailure: () => failure,),
      successStateBuilder: (state) => state.copyWith(status: MyPostListStatus.loaded),
    );
  }

  // Future<void> _onMyPostLikeToggled(
  //   MyPostLikeToggled event,
  //   Emitter<MyPostListState> emit,
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

  Future<void> _onMyPostListRefillRequested(
    _MyPostListRefillRequested event,
    Emitter<MyPostListState> emit,
  ) async {
    if (_isBusy || state.hasReachedMax || _userId == null) return;

    emit(state.copyWith(status: MyPostListStatus.refilling));

    final newState = await _paginationHandler.fetchOneToRefill(
      currentState: state,
      fetchPostsStrategy: ({required int offset, required int limit}) {
        return _getMyPostUsecase(
          GetMyPostParams(userId: _userId!, offset: offset, limit: limit),
        );
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

  // Future<void> _onMyPostListRefillRequested(
  //   _MyPostListRefillRequested event,
  //   Emitter<MyPostListState> emit,
  // ) async {
  //   if (_isBusy || state.hasReachedMax || _userId == null) return;

  //   emit(state.copyWith(status: MyPostListStatus.refilling));

  //   final result = await _getMyPostUsecase(
  //     GetMyPostParams(userId: _userId!, offset: state.posts.length, limit: 1),
  //   );

  //   result.fold(
  //     (failure) {
  //       emit(
  //         state.copyWith(
  //           status: MyPostListStatus.loaded,
  //           transientFailure: () => failure,
  //         ),
  //       );
  //     },
  //     (newPosts) {
  //       if (newPosts.isNotEmpty) {
  //         emit(
  //           state.copyWith(
  //             status: MyPostListStatus.loaded,
  //             posts: [...state.posts, ...newPosts],
  //           ),
  //         );
  //       } else {
  //         emit(
  //           state.copyWith(
  //             status: MyPostListStatus.loaded,
  //             hasReachedMax: true,
  //           ),
  //         );
  //       }
  //     },
  //   );
  // }

  void _onGlobalEventReceived(
    _GlobalEventReceived event,
    Emitter<MyPostListState> emit,
  ) {
    if (state.status != MyPostListStatus.fetchingNextPage && _isBusy) return;

    switch (event.event) {
      case PostCreatedDispatched(post: final newPost):
        final currentPosts = state.posts;
        emit(state.copyWith(posts: [newPost, ...currentPosts]));

      case PostUpdateDispatched(post: final updatePost):
        final currentPosts = state.posts;
        final newPosts = currentPosts.map((p) {
          return p.postId == updatePost.postId ? updatePost : p;
        }).toList();
        emit(state.copyWith(posts: newPosts));

      case PostDeletedDispatched(postId: final deletedPostId):
        final currentPost = state.posts;
        final newPosts = currentPost
            .where((p) => p.postId != deletedPostId)
            .toList();
        emit(state.copyWith(posts: newPosts));

        if (newPosts.length < currentPost.length) {
          add(_MyPostListRefillRequested());
        }

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
}
