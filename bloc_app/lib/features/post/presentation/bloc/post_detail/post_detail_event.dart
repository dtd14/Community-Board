part of 'post_detail_bloc.dart';

sealed class PostDetailEvent extends Equatable {
  const PostDetailEvent();

  @override
  List<Object> get props => [];
}

final class PostDetailFetched extends PostDetailEvent {
  const PostDetailFetched({required this.postId});

  final String postId;

  @override
  List<Object> get props => [];
}

final class PostDetailLikeToggled extends PostDetailEvent {
  const PostDetailLikeToggled();
}

final class PostDeleted extends PostDetailEvent {
  const PostDeleted();
}

final class PostDetailTransientFailureComsumed extends PostDetailEvent{}

final class _PostUpdatedFrombus extends PostDetailEvent {
  const _PostUpdatedFrombus({required this.post});

  final PostDisplay post;

  @override
  List<Object> get props => [post];
}
