part of 'post_people_bloc.dart';

enum PostPeopleStatus { initial, loading, loaded, loadingMore, failure }

class PostPeopleState extends Equatable {
  const PostPeopleState({
    this.status = PostPeopleStatus.initial,
    this.postId = '',
    this.kind = PostPeopleKind.likes,
    this.people = const [],
    this.totalCount = 0,
    this.hasReachedMax = false,
    this.failure,
  });
  final PostPeopleStatus status;
  final String postId;
  final PostPeopleKind kind;
  final List<PostPerson> people;
  final int totalCount;
  final bool hasReachedMax;
  final Failures? failure;

  PostPeopleState copyWith({
    PostPeopleStatus? status,
    List<PostPerson>? people,
    int? totalCount,
    bool? hasReachedMax,
    Failures? Function()? failure,
  }) => PostPeopleState(
    status: status ?? this.status,
    postId: postId,
    kind: kind,
    people: people ?? this.people,
    totalCount: totalCount ?? this.totalCount,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    postId,
    kind,
    people,
    totalCount,
    hasReachedMax,
    failure,
  ];
}
