import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_app/features/auth/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:bloc_app/features/post/presentation/bloc/comments_list/comments_list_bloc.dart';
import 'package:bloc_app/features/post/presentation/bloc/post_detail/post_detail_bloc.dart';
import 'package:bloc_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:bloc_app/features/post/presentation/widgets/comment_card.dart';
import 'package:bloc_app/features/post/presentation/widgets/post_card.dart';

class _AuthenticationBlocStub extends Fake implements AuthenticationBloc {
  @override
  AuthenticationState get state => const AuthenticationState.unauthenticated();

  @override
  Stream<AuthenticationState> get stream => const Stream.empty();
}

class _CommentsListBlocStub extends Fake implements CommentsListBloc {
  @override
  CommentsListState get state => const CommentsListState(
    status: CommentListStatus.loaded,
    hasReachedMax: true,
  );

  @override
  Stream<CommentsListState> get stream => const Stream.empty();

  @override
  void add(CommentsListEvent event) {}
}

class _PostDetailBlocStub extends Fake implements PostDetailBloc {
  _PostDetailBlocStub(this.post);

  final PostDisplay post;

  @override
  PostDetailState get state =>
      PostDetailState(status: PostDetailStatus.loaded, post: post);

  @override
  Stream<PostDetailState> get stream => const Stream.empty();
}

PostDisplay _post(DateTime createdAt) => PostDisplay(
  postId: 'post-1',
  title: 'Local time test',
  content: 'Post content',
  postCreatedAt: createdAt,
  postUpdatedAt: createdAt,
  authorId: 'author-1',
  authorUsername: 'Author',
  authorRole: 'user',
  likesCount: 0,
  commentsCount: 0,
  currentUserLiked: false,
);

Widget _app(Widget child, PostDisplay post) => MultiBlocProvider(
  providers: [
    BlocProvider<AuthenticationBloc>.value(value: _AuthenticationBlocStub()),
    BlocProvider<CommentsListBloc>.value(value: _CommentsListBlocStub()),
    BlocProvider<PostDetailBloc>.value(value: _PostDetailBlocStub(post)),
  ],
  child: MaterialApp(home: child),
);

void main() {
  // Known device-local wall times keep these checks independent of the CI
  // timezone and of the conversion used by the widgets.
  final evening = DateTime(2026, 10, 12, 23, 45);
  final midnight = DateTime(2026, 10, 13, 0, 15);
  final vietnamTimestamp = evening
      .toUtc()
      .add(const Duration(hours: 7))
      .toIso8601String()
      .replaceFirst('Z', '+07:00');
  final cases = [
    (
      name: 'UTC timestamp',
      time: DateTime.parse(evening.toUtc().toIso8601String()),
      postText: '2026-10-12 23:45',
      commentText: '10-12 23:45',
    ),
    (
      name: 'timestamp with +07:00 offset',
      time: DateTime.parse(vietnamTimestamp),
      postText: '2026-10-12 23:45',
      commentText: '10-12 23:45',
    ),
    (
      name: 'UTC timestamp around local midnight',
      time: DateTime.parse(midnight.toUtc().toIso8601String()),
      postText: '2026-10-13 00:15',
      commentText: '10-13 00:15',
    ),
    (
      name: 'already-local timestamp',
      time: evening,
      postText: '2026-10-12 23:45',
      commentText: '10-12 23:45',
    ),
  ];

  for (final scenario in cases) {
    testWidgets('Post card shows local time: ${scenario.name}', (tester) async {
      final post = _post(scenario.time);
      await tester.pumpWidget(_app(Scaffold(body: PostCard(post: post)), post));

      expect(find.text(scenario.postText), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(post.postCreatedAt, scenario.time);
    });

    testWidgets('Post detail shows local time: ${scenario.name}', (
      tester,
    ) async {
      final post = _post(scenario.time);
      await tester.pumpWidget(
        _app(const PostDetailView(postId: 'post-1'), post),
      );

      expect(find.text(scenario.postText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Comment shows local time: ${scenario.name}', (tester) async {
      final post = _post(scenario.time);
      final comment = CommentDisplay(
        id: 'comment-1',
        postId: post.postId,
        content: 'Comment content',
        createdAt: scenario.time,
        authorId: post.authorId,
        authorUsername: post.authorUsername,
      );
      await tester.pumpWidget(
        _app(Scaffold(body: CommentCard(comment: comment)), post),
      );

      expect(find.text(scenario.commentText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
