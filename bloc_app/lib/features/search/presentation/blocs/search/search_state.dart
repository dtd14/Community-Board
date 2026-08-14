part of 'search_bloc.dart';

enum SearchStatus { initial, loadingUsers, loadingPosts, loaded, failure }

class SearchState {
  const SearchState({
     this.status = SearchStatus.initial,
     this.users = const [],
     this.posts = const [],
     this.query = '',
     this.currentTabIndex = 0,
     this.failure,
     this.transientFailure,
  });

  final SearchStatus status;
  final List<UserEntity> users;
  final List<PostDisplay> posts;
  final String query;
  final int currentTabIndex;
  final Failures? failure;
  final Failures? transientFailure;

  SearchState copyWith({
    SearchStatus? status,
    List<UserEntity>? users,
    List<PostDisplay>? posts,
    String? query,
    int? currentTabIndex,
    Failures? Function()? failure,
    Failures? Function()? transientFailure,
  }) {
    return SearchState(
      status: status ?? this.status,
      users: users ?? this.users,
      posts: posts ?? this.posts,
      query: query ?? this.query,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      failure: failure != null ? failure() : this.failure,
      transientFailure: transientFailure != null ? transientFailure() : this.transientFailure,
    );
  }
}
