part of 'comments_list_bloc.dart';

enum CommentListStatus {
  initial,
  loading,
  loaded,
  failure,
  fetchingNextPage,
  submitting,
  refilling,
  refreshing,
}

class CommentsListState extends Equatable {
  const CommentsListState({
    this.status = CommentListStatus.initial,
    this.comments = const [],
    this.hasReachedMax = false,
    this.failure,
    this.transientFailure,
    this.submittingCommentId,
  });
  final CommentListStatus status;
  final List<CommentDisplay> comments;
  final bool hasReachedMax;
  final Failures? failure;
  final Failures? transientFailure;
  final String? submittingCommentId;

  @override
  List<Object?> get props => [
    comments,
    status,
    hasReachedMax,
    failure,
    transientFailure,
    submittingCommentId,
  ];

  CommentsListState copyWith({
    CommentListStatus? status,
    List<CommentDisplay>? comments,
    bool? hasReachedMax,
    Failures? Function()? failure,
    Failures? Function()? transientFailure,
    String? Function()? submittingCommentId,
  }) {
    return CommentsListState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      failure: failure != null ? failure() : this.failure,
      transientFailure: transientFailure != null ? transientFailure() : this.transientFailure,
      submittingCommentId: submittingCommentId != null ? submittingCommentId() : this.submittingCommentId,
    );
  }
}
