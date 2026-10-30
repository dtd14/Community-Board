part of 'post_people_bloc.dart';

sealed class PostPeopleEvent extends Equatable {
  const PostPeopleEvent();
  @override
  List<Object> get props => [];
}

final class PostPeopleFetched extends PostPeopleEvent {
  const PostPeopleFetched({required this.postId, required this.kind});
  final String postId;
  final PostPeopleKind kind;
  @override
  List<Object> get props => [postId, kind];
}

final class PostPeopleNextPageFetched extends PostPeopleEvent {}
