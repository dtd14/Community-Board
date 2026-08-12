import 'package:bloc/bloc.dart';
import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/bus/global_event.dart';
import '../../../../../core/bus/global_event_bus.dart';

part 'comments_list_event.dart';
part 'comments_list_state.dart';

const _commentPageSize = 10;

@injectable
class CommentsListBloc extends Bloc<CommentsListEvent, CommentsListState> {
  CommentsListBloc({
    required this._getCommentsUsecase,
    required this._createCommentUsecase,
    required this._deleteCommentUsecase,
    required this._updateCommentUsecase,
    required this._getPostDetailUsecase,
    required this._globalEventBus,
  }) : super(const CommentsListState()) {
    on<CommentListFetched>(_onCommentsListFetched);
    on<CommentListNextPageFetched>(_onCommentListNextPageFetched);
    on<CommentListRefreshed>(_onCommentListRefreshed);
    on<CommentListTrasientFailureConsumed>(
      _onCommentListTrasientFailureConsumed,
    );
    on<CommentAdded>(_onCommentAdded);
    on<CommentDeleted>(_onCommentDeleted);
    on<_CommentListRefillRequested>(_onCommentListRefillRequested);
    on<CommentEdited>(_onCommentEdited);
  }
  final GetCommentsUsecase _getCommentsUsecase;
  final CreateCommentUsecase _createCommentUsecase;
  final DeleteCommentUsecase _deleteCommentUsecase;
  final UpdateCommentUsecase _updateCommentUsecase;
  final GetPostDetailUsecase _getPostDetailUsecase;
  final GlobalEventBus _globalEventBus;

  bool _isBusy() =>
      state.status == CommentListStatus.loading ||
      state.status == CommentListStatus.fetchingNextPage ||
      state.status == CommentListStatus.submitting ||
      state.status == CommentListStatus.refilling ||
      state.status == CommentListStatus.refreshing ||
      state.submittingCommentId != null;

  Future<void> _onCommentsListFetched(
    CommentListFetched event,
    Emitter<CommentsListState> emit,
  ) async {
    if (_isBusy()) return;

    emit(state.copyWith(status: CommentListStatus.loading));

    final result = await _getCommentsUsecase(
      GetCommentsParams(
        postId: event.postId,
        offset: 0,
        limit: _commentPageSize,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CommentListStatus.failure,
          failure: () => failure,
        ),
      ),
      (comments) => emit(
        state.copyWith(
          status: CommentListStatus.loaded,
          comments: comments,
          hasReachedMax: comments.length < _commentPageSize,
        ),
      ),
    );
  }

  Future<void> _onCommentListNextPageFetched(
    CommentListNextPageFetched event,
    Emitter<CommentsListState> emit,
  ) async {
    if (_isBusy() || state.hasReachedMax) return;

    emit(state.copyWith(status: CommentListStatus.fetchingNextPage));

    final result = await _getCommentsUsecase(
      GetCommentsParams(
        postId: event.postId,
        offset: state.comments.length,
        limit: _commentPageSize,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CommentListStatus.loaded,
          transientFailure: () => failure,
        ),
      ),
      (newComments) => emit(
        state.copyWith(
          status: CommentListStatus.loaded,
          comments: [...state.comments, ...newComments],
          hasReachedMax: newComments.length < _commentPageSize,
        ),
      ),
    );
  }

  Future<void> _onCommentListRefreshed(
    CommentListRefreshed event,
    Emitter<CommentsListState> emit,
  ) async {
    if (_isBusy()) return;

    emit(state.copyWith(status: CommentListStatus.refreshing));

    final result = await _getCommentsUsecase(
      GetCommentsParams(
        postId: event.postId,
        offset: 0,
        limit: _commentPageSize,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CommentListStatus.failure,
          transientFailure: () => failure,
        ),
      ),
      (comments) => emit(
        state.copyWith(
          status: CommentListStatus.loaded,
          comments: comments,
          hasReachedMax: comments.length < _commentPageSize,
        ),
      ),
    );
  }

  void _onCommentListTrasientFailureConsumed(
    CommentListTrasientFailureConsumed event,
    Emitter<CommentsListState> emit,
  ) {
    emit(state.copyWith(transientFailure: () => null));
  }

  Future<void> _onCommentAdded(
    CommentAdded event,
    Emitter<CommentsListState> emit,
  ) async {
    if (_isBusy()) return;

    emit(
      state.copyWith(
        status: CommentListStatus.submitting,
        transientFailure: () => null,
      ),
    );
    final result = await _createCommentUsecase(
      CreateCommentParams(postId: event.postId, content: event.content),
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: CommentListStatus.loaded,
          transientFailure: () => failure,
        ),
      ),
      (newComment) async {
        final updateComments = [newComment, ...state.comments];
        emit(
          state.copyWith(
            status: CommentListStatus.loaded,
            comments: updateComments,
          ),
        );
        final postResult = await _getPostDetailUsecase(event.postId);
        postResult.fold((l) => null, (updatePost) {
          _globalEventBus.add(PostUpdateDispatched(post: updatePost));
        });
      },
    );
  }

  Future<void> _onCommentDeleted(
    CommentDeleted event,
    Emitter<CommentsListState> emit,
  ) async {
    if (_isBusy()) return;

    emit(
      state.copyWith(
        submittingCommentId: () => event.commentId,
        transientFailure: () => null,
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    final result = await _deleteCommentUsecase(event.commentId);

    await result.fold(
      (failure) {
        emit(
          state.copyWith(
            submittingCommentId: () => null,
            transientFailure: () => failure,
          ),
        );
      },
      (_) async {
        final updateComments = List<CommentDisplay>.from(state.comments)
          ..removeWhere((c) => c.id == event.commentId);

        emit(
          state.copyWith(
            comments: updateComments,
            submittingCommentId: () => null,
          ),
        );

        add(_CommentListRefillRequested(postId: event.postId));

        final postResult = await _getPostDetailUsecase(event.postId);
        postResult.fold((l) => null, (updatedPost) {
          _globalEventBus.add(PostUpdateDispatched(post: updatedPost));
        });
      },
    );
  }

  Future<void> _onCommentListRefillRequested(
    _CommentListRefillRequested event,
    Emitter<CommentsListState> emit,
  ) async {
    if (_isBusy() || state.hasReachedMax) return;

    emit(state.copyWith(status: CommentListStatus.refilling));

    final result = await _getCommentsUsecase(
      GetCommentsParams(
        postId: event.postId,
        offset: state.comments.length,
        limit: 1,
      ),
    );
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: CommentListStatus.loaded,
            transientFailure: () => failure,
          ),
        );
      },
      (newComments) {
        if (newComments.isNotEmpty) {
          emit(
            state.copyWith(
              status: CommentListStatus.loaded,
              comments: [...state.comments, ...newComments],
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: CommentListStatus.loaded,
              hasReachedMax: true,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCommentEdited(
    CommentEdited event,
    Emitter<CommentsListState> emit,
  ) async {
    if (_isBusy()) return;

    emit(
      state.copyWith(
        submittingCommentId: () => event.commentId,
        transientFailure: () => null,
      ),
    );
    await Future.delayed(const Duration(seconds: 1));

    final result = await _updateCommentUsecase(
      UpdateCommentParams(
        commentId: event.commentId,
        newContent: event.newContent,
      ),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            submittingCommentId: () => null,
            transientFailure: () => failure,
          ),
        );
      },
      (updateComment) {
        final updateList = state.comments.map((comment) {
          return comment.id == updateComment.id ? updateComment : comment;
        }).toList();

        emit(
          state.copyWith(comments: updateList, submittingCommentId: () => null),
        );
      },
    );
  }
}
