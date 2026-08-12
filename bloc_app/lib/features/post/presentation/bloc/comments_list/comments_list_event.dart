part of 'comments_list_bloc.dart';

sealed class CommentsListEvent extends Equatable {
  const CommentsListEvent();

  @override
  List<Object> get props => [];
}

final class CommentListFetched extends CommentsListEvent {
  const CommentListFetched({required this.postId});

  final String postId;
  @override
  List<Object> get props => [postId];
}

final class CommentListNextPageFetched extends CommentsListEvent {
  const CommentListNextPageFetched({required this.postId});

  final String postId;
  @override
  List<Object> get props => [postId];
}

final class CommentListRefreshed extends CommentsListEvent {
  const CommentListRefreshed({required this.postId});

  final String postId;
  @override
  List<Object> get props => [postId];
}

final class CommentListTrasientFailureConsumed extends CommentsListEvent {}

final class CommentAdded extends CommentsListEvent {
  const CommentAdded({required this.postId, required this.content});

  final String postId;
  final String content;

  @override
  List<Object> get props => [postId, content];
}

final class CommentDeleted extends CommentsListEvent {
  const CommentDeleted({required this.postId, required this.commentId});

  final String postId;
  final String commentId;

  @override
  List<Object> get props => [postId, commentId];
}

final class CommentEdited extends CommentsListEvent {
  const CommentEdited({required this.commentId, required this.newContent});

  final String commentId;
  final String newContent;

  @override
  List<Object> get props => [newContent, commentId];
}

final class _CommentListRefillRequested extends CommentsListEvent {
  const _CommentListRefillRequested({required this.postId});

  final String postId;

  @override
  List<Object> get props => [postId];
}
