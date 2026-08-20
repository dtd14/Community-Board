import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:fpdart/fpdart.dart';

typedef FetchPostsStrategy =
    Future<Either<Failures, List<PostDisplay>>> Function({
      required int offset,
      required int limit,
    });

class PaginationHandler<S> {
  Future<S> fetchNextPage({
    required S currentState,
    required FetchPostsStrategy fetchPostsStrategy,
    required int pagesize,
    required S Function() getLastestState,
    required List<PostDisplay> Function(S state) getPosts,
    required S Function(S state, List<PostDisplay> newPosts) copyWithPosts,
    required S Function(S state, bool hasReachedMax) copyWithHasReachedMax,
    required S Function(S state, Failures failure) copyWithTransientFailure,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final result = await fetchPostsStrategy(
      offset: getPosts(currentState).length,
      limit: pagesize,
    );

    final latestState = getLastestState();

    return result.fold(
      (failure) => copyWithTransientFailure(latestState, failure),
      (newPosts) {
        final updatedPosts = getPosts(latestState) + newPosts;
        final newState = copyWithPosts(latestState, updatedPosts);
        if (newPosts.length < pagesize) {
          return copyWithHasReachedMax(newState, true);
        }
        return newState;
      },
    );
  }

  Future<S> fetchOneToRefill({
    required S currentState,
    required FetchPostsStrategy fetchPostsStrategy,
    required S Function() getLastestState,
    required List<PostDisplay> Function(S state) getPosts,
    required S Function(S state, List<PostDisplay> newPosts) copyWithPosts,
    required S Function(S state, bool hasReachedMax) copyWithHasReachedMax,
    required S Function(S state, Failures failure) copyWithTransientFailure,
  }) async {
    final result = await fetchPostsStrategy(
      limit: 1,
      offset: getPosts(currentState).length,
    );

    final latestState = getLastestState();

    return result.fold(
      (failure) => copyWithTransientFailure(latestState, failure),
      (newPosts) {
        if (newPosts.isNotEmpty) {
          final updatePost = [...getPosts(latestState), ...newPosts];
          return copyWithPosts(latestState, updatePost);
        } else {
          return copyWithHasReachedMax(latestState, true);
        }
      },
    );
  }
}
