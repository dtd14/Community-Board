import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/bus/global_event.dart';
import '../../../../../core/bus/global_event_bus.dart';
import '../../handlers/toggle_like_handler.dart';

part 'post_list_event.dart';
part 'post_list_state.dart';

const _pageSize = 10;

@injectable
class PostListBloc extends Bloc<PostListEvent, PostListState> {
  PostListBloc({
    required this._getPostsUsecase,
    required this._globalEventBus,
    required this._toggleLikeUsecase,
  }) : super(const PostListState()) {
    _toggleLikeHandler = ToggleLikeHandler(
      toggleLikeUseCase: _toggleLikeUsecase,
      globalEventBus: _globalEventBus,
    );
    on<PostListFetched>((event, emit) => _loadFirstPage(emit));
    on<PostListRefreshed>((event, emit) => _loadFirstPage(emit, refresh: true));
    on<PostListCategoryChanged>((event, emit) async {
      emit(
        state.copyWith(
          category: () => event.category,
          posts: [],
          hasReachedMax: false,
        ),
      );
      await _loadFirstPage(emit);
    });
    on<PostListNextPageFetched>(_onNextPage);
    on<PostLikeToggled>(_onLike);
    on<_GlobalEventReceived>(_onGlobalEvent);
    on<PostListNewPostPrepended>((event, emit) {
      // Reload from the server so pinned ordering and paging remain correct.
      add(PostListRefreshed());
    });
    on<PostListTransientFailureConsumed>(
      (event, emit) => emit(state.copyWith(transientFailure: () => null)),
    );
    on<PostListScrollToTop>(
      (event, emit) => emit(
        state.copyWith(
          scrollToTopEventId: () => DateTime.now().microsecondsSinceEpoch,
        ),
      ),
    );
    on<PostListEventScrollConsumed>(
      (event, emit) => emit(state.copyWith(scrollToTopEventId: () => null)),
    );
    on<PostListResetRequested>((event, emit) {
      ++_requestId;
      _nextOffset = 0;
      emit(const PostListState());
    });
    _subscription = _globalEventBus.stream.listen(
      (event) => add(_GlobalEventReceived(event: event)),
    );
  }
  final GetPostsUsecase _getPostsUsecase;
  final GlobalEventBus _globalEventBus;
  final ToggleLikeUsecase _toggleLikeUsecase;
  late final ToggleLikeHandler<PostListState> _toggleLikeHandler;
  StreamSubscription<GlobalEvent>? _subscription;
  final Set<String> _likingIds = {};
  int _requestId = 0;
  int _nextOffset = 0;

  Future<void> _loadFirstPage(
    Emitter<PostListState> emit, {
    bool refresh = false,
  }) async {
    final requestId = ++_requestId;
    emit(
      state.copyWith(
        status: refresh && state.posts.isNotEmpty
            ? PostListStatus.refreshing
            : PostListStatus.loading,
        failure: () => null,
        transientFailure: () => null,
      ),
    );
    final result = await _getPostsUsecase(
      GetPostsParams(offset: 0, limit: _pageSize, category: state.category),
    );
    if (requestId != _requestId || emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: state.posts.isEmpty
              ? PostListStatus.failure
              : PostListStatus.loaded,
          failure: () => failure,
          transientFailure: () => state.posts.isEmpty ? null : failure,
        ),
      ),
      (posts) {
        _nextOffset = posts.length;
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

  Future<void> _onNextPage(
    PostListNextPageFetched event,
    Emitter<PostListState> emit,
  ) async {
    if (state.status != PostListStatus.loaded || state.hasReachedMax) return;
    final requestId = _requestId;
    emit(state.copyWith(status: PostListStatus.fetchingNextPage));
    final result = await _getPostsUsecase(
      GetPostsParams(
        offset: _nextOffset,
        limit: _pageSize,
        category: state.category,
      ),
    );
    if (requestId != _requestId || emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PostListStatus.loaded,
          transientFailure: () => failure,
        ),
      ),
      (posts) {
        _nextOffset += posts.length;
        final merged = {for (final post in state.posts) post.postId: post};
        for (final post in posts) {
          merged[post.postId] = post;
        }
        emit(
          state.copyWith(
            status: PostListStatus.loaded,
            posts: merged.values.toList(),
            hasReachedMax: posts.length < _pageSize,
          ),
        );
      },
    );
  }

  Future<void> _onLike(
    PostLikeToggled event,
    Emitter<PostListState> emit,
  ) async {
    if (state.status != PostListStatus.loaded ||
        !_likingIds.add(event.post.postId)) {
      return;
    }
    final requestId = _requestId;
    try {
      await _toggleLikeHandler.execute(
        emit: emit,
        initialState: state,
        postToToggle: event.post,
        getLastestState: () => state,
        getPosts: (state) => state.posts,
        copyWithPosts: (state, posts) =>
            requestId == _requestId ? state.copyWith(posts: posts) : state,
        copyWithTransientFailure: (state, failure) => requestId == _requestId
            ? state.copyWith(transientFailure: () => failure)
            : state,
        successStateBuilder: (state) => state,
      );
    } finally {
      _likingIds.remove(event.post.postId);
    }
  }

  void _onGlobalEvent(_GlobalEventReceived event, Emitter<PostListState> emit) {
    switch (event.event) {
      case PostCreatedDispatched() || PostDeletedDispatched():
        add(PostListRefreshed());
      case PostUpdateDispatched(:final post):
        final index = state.posts.indexWhere((p) => p.postId == post.postId);
        if (index < 0) return;
        final old = state.posts[index];
        if (old.category != post.category || old.isPinned != post.isPinned) {
          add(PostListRefreshed());
          return;
        }
        emit(
          state.copyWith(
            posts: state.posts
                .map((p) => p.postId == post.postId ? post : p)
                .toList(),
          ),
        );
      case ProfileUpdatedDispatched(:final profile):
        emit(
          state.copyWith(
            posts: state.posts
                .map(
                  (p) => p.authorId == profile.id
                      ? p.copyWith(
                          authorUsername: profile.username,
                          authorAvatarUrl: () => profile.avatarUrl,
                        )
                      : p,
                )
                .toList(),
          ),
        );
    }
  }

  @override
  Future<void> close() {
    ++_requestId;
    _subscription?.cancel();
    return super.close();
  }
}
