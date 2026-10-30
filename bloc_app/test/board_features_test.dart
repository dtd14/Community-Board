import 'dart:async';
import 'dart:typed_data';

import 'package:core/errors.dart';
import 'package:data_supabase/post.dart';
import 'package:domain/post.dart';
import 'package:domain/media.dart';
import 'package:domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:bloc_app/core/bus/global_event.dart';
import 'package:bloc_app/core/bus/global_event_bus.dart';
import 'package:bloc_app/features/post/presentation/bloc/post_detail/post_detail_bloc.dart';
import 'package:bloc_app/features/post/presentation/bloc/post_list/post_list_bloc.dart';
import 'package:bloc_app/features/post/presentation/bloc/post_people/post_people_bloc.dart';

PostDisplay makePost(
  String id, {
  String category = PostCategories.announcement,
}) => PostDisplay(
  postId: id,
  title: 'Thông báo',
  content: 'Nội dung',
  postCreatedAt: DateTime.utc(2026, 10, 20),
  postUpdatedAt: DateTime.utc(2026, 10, 20),
  authorId: 'admin',
  authorUsername: 'Nhân sự',
  authorRole: 'admin',
  likesCount: 0,
  commentsCount: 0,
  currentUserLiked: false,
  category: category,
  requiresAcknowledgement: true,
  contentVersion: 3,
);

class BoardRepositoryFake extends Fake implements PostRepository {
  final feedRequests =
      <
        ({
          String? category,
          int offset,
          Completer<Either<Failures, List<PostDisplay>>> result,
        })
      >[];
  final peopleRequests =
      <
        ({
          PostPeopleKind kind,
          int offset,
          Completer<Either<Failures, PostPeoplePage>> result,
        })
      >[];
  final acknowledgement = Completer<Either<Failures, PostDisplay>>();
  int acknowledgementCalls = 0;
  int? acknowledgedVersion;

  @override
  Future<Either<Failures, List<PostDisplay>>> getPost({
    String? category,
    required int offset,
    required int limit,
  }) {
    final result = Completer<Either<Failures, List<PostDisplay>>>();
    feedRequests.add((category: category, offset: offset, result: result));
    return result.future;
  }

  @override
  Future<Either<Failures, PostPeoplePage>> getPostPeople({
    required String postId,
    required PostPeopleKind kind,
    required int offset,
    required int limit,
  }) {
    final result = Completer<Either<Failures, PostPeoplePage>>();
    peopleRequests.add((kind: kind, offset: offset, result: result));
    return result.future;
  }

  @override
  Future<Either<Failures, PostDisplay>> getPostDetail({
    required String postId,
  }) async => Right(makePost(postId));

  @override
  Future<Either<Failures, PostDisplay>> acknowledgePost({
    required String postId,
    required int contentVersion,
  }) {
    acknowledgementCalls++;
    acknowledgedVersion = contentVersion;
    return acknowledgement.future;
  }
}

Future<void> settleEvents() async {
  // Let the asynchronous BLoC event queue process without using wall-clock delays.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _PostImageFailure extends Fake implements PostRepository {
  int deletions = 0;
  int updates = 0;
  @override
  Future<Either<Failures, ImageUploadResult>> uploadPostImage({
    required UploadImage image,
    String? postId,
  }) async => const Left(NetworkFailure());
  @override
  Future<Either<Failures, void>> deletePostFolder({
    required String postId,
  }) async {
    deletions++;
    return const Right(null);
  }

  @override
  Future<Either<Failures, PostDisplay>> updatePost({
    required String postId,
    required String title,
    required String content,
    String? imageUrl,
    String category = PostCategories.announcement,
    bool isPinned = false,
    bool requiresAcknowledgement = false,
  }) async {
    updates++;
    return Right(makePost(postId));
  }
}

class _AvatarFailure extends Fake implements ProfileRepository {
  int deletions = 0;
  @override
  Future<Either<Failures, String>> uploadAvatar({
    required UploadImage image,
    required String userId,
  }) async => const Left(NetworkFailure());
  @override
  Future<Either<Failures, void>> deleteAvatar(String avatarUrl) async {
    deletions++;
    return const Right(null);
  }
}

void main() {
  test('Failed replacement upload preserves the existing post image', () async {
    final repository = _PostImageFailure();
    final original = makePost(
      'post',
    ).copyWith(imageUrl: () => 'https://example.test/old.png');
    final result = await UpdatePostUsecase(postRepository: repository)(
      UpdatePostParams(
        originalPost: original,
        newTitle: original.title,
        newContent: original.content,
        newImageFile: UploadImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          name: 'new.png',
        ),
      ),
    );
    expect(result.isLeft(), isTrue);
    expect(repository.deletions, 0);
    expect(repository.updates, 0);
    expect(original.imageUrl, 'https://example.test/old.png');
  });

  test('Failed replacement upload preserves the existing avatar', () async {
    final repository = _AvatarFailure();
    final result = await UpdateProfileUsecase(profileRepository: repository)(
      UpdateProfileParams(
        userId: 'member',
        username: 'Lan',
        originalAvatarUrl: 'https://example.test/old.png',
        newAvatarFile: UploadImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          name: 'new.png',
        ),
      ),
    );
    expect(result.isLeft(), isTrue);
    expect(repository.deletions, 0);
  });
  test(
    'Changing category discards a late response from the previous category',
    () async {
      final repository = BoardRepositoryFake();
      final bus = GlobalEventBus();
      final bloc = PostListBloc(
        getPostsUsecase: GetPostsUsecase(postRepository: repository),
        globalEventBus: bus,
        toggleLikeUsecase: ToggleLikeUsecase(postRepository: repository),
      );
      addTearDown(() async {
        await bloc.close();
        bus.dispose();
      });
      bloc.add(PostListFetched());
      await settleEvents();
      bloc.add(const PostListCategoryChanged(category: PostCategories.policy));
      await settleEvents();
      expect(repository.feedRequests[1].category, PostCategories.policy);
      repository.feedRequests[1].result.complete(
        Right([makePost('policy', category: PostCategories.policy)]),
      );
      await settleEvents();
      repository.feedRequests[0].result.complete(Right([makePost('old')]));
      await settleEvents();
      expect(bloc.state.posts.single.postId, 'policy');
      expect(bloc.state.category, PostCategories.policy);
    },
  );

  test('Paging keeps the category and does not duplicate posts', () async {
    final repository = BoardRepositoryFake();
    final bus = GlobalEventBus();
    final bloc = PostListBloc(
      getPostsUsecase: GetPostsUsecase(postRepository: repository),
      globalEventBus: bus,
      toggleLikeUsecase: ToggleLikeUsecase(postRepository: repository),
    );
    addTearDown(() async {
      await bloc.close();
      bus.dispose();
    });
    bloc.add(const PostListCategoryChanged(category: PostCategories.policy));
    await settleEvents();
    repository.feedRequests[0].result.complete(
      Right(
        List.generate(
          10,
          (i) => makePost('$i', category: PostCategories.policy),
        ),
      ),
    );
    await settleEvents();
    bloc.add(PostListNextPageFetched());
    await settleEvents();
    expect(repository.feedRequests[1].category, PostCategories.policy);
    expect(repository.feedRequests[1].offset, 10);
    repository.feedRequests[1].result.complete(
      Right([makePost('9'), makePost('10')]),
    );
    await settleEvents();
    expect(bloc.state.posts.length, 11);
    expect(bloc.state.hasReachedMax, isTrue);
  });

  test(
    'A response arriving after logout does not restore the previous feed',
    () async {
      final repository = BoardRepositoryFake();
      final bus = GlobalEventBus();
      final bloc = PostListBloc(
        getPostsUsecase: GetPostsUsecase(postRepository: repository),
        globalEventBus: bus,
        toggleLikeUsecase: ToggleLikeUsecase(postRepository: repository),
      );
      addTearDown(() async {
        await bloc.close();
        bus.dispose();
      });
      bloc.add(PostListFetched());
      await settleEvents();
      bloc.add(PostListResetRequested());
      await settleEvents();
      repository.feedRequests.single.result.complete(
        Right([makePost('private')]),
      );
      await settleEvents();
      expect(bloc.state.posts, isEmpty);
      expect(bloc.state.status, PostListStatus.initial);
    },
  );

  test(
    'People tabs ignore stale responses and pass the selected kind',
    () async {
      final repository = BoardRepositoryFake();
      final bloc = PostPeopleBloc(
        getPostPeopleUsecase: GetPostPeopleUsecase(postRepository: repository),
      );
      addTearDown(bloc.close);
      bloc.add(
        const PostPeopleFetched(
          postId: 'post',
          kind: PostPeopleKind.acknowledged,
        ),
      );
      await settleEvents();
      bloc.add(
        const PostPeopleFetched(postId: 'post', kind: PostPeopleKind.pending),
      );
      await settleEvents();
      repository.peopleRequests[1].result.complete(
        const Right(
          PostPeoplePage(
            people: [PostPerson(userId: 'pending', username: 'Lan')],
            totalCount: 1,
          ),
        ),
      );
      await settleEvents();
      repository.peopleRequests[0].result.complete(
        const Right(
          PostPeoplePage(
            people: [PostPerson(userId: 'old', username: 'Minh')],
            totalCount: 1,
          ),
        ),
      );
      await settleEvents();
      expect(bloc.state.kind, PostPeopleKind.pending);
      expect(bloc.state.people.single.userId, 'pending');
    },
  );

  test(
    'People paging failure retains the first page and retries the same offset',
    () async {
      final repository = BoardRepositoryFake();
      final bloc = PostPeopleBloc(
        getPostPeopleUsecase: GetPostPeopleUsecase(postRepository: repository),
      );
      addTearDown(bloc.close);
      bloc.add(
        const PostPeopleFetched(postId: 'post', kind: PostPeopleKind.likes),
      );
      await settleEvents();
      repository.peopleRequests[0].result.complete(
        Right(
          PostPeoplePage(
            people: List.generate(
              20,
              (i) => PostPerson(userId: '$i', username: 'User $i'),
            ),
            totalCount: 21,
          ),
        ),
      );
      await settleEvents();
      bloc.add(PostPeopleNextPageFetched());
      await settleEvents();
      repository.peopleRequests[1].result.complete(
        const Left(NetworkFailure()),
      );
      await settleEvents();
      expect(bloc.state.people.length, 20);
      expect(bloc.state.failure, isA<NetworkFailure>());
      bloc.add(PostPeopleNextPageFetched());
      await settleEvents();
      expect(repository.peopleRequests[2].offset, 20);
      repository.peopleRequests[2].result.complete(
        const Right(
          PostPeoplePage(
            people: [PostPerson(userId: '20', username: 'Last')],
            totalCount: 21,
          ),
        ),
      );
      await settleEvents();
      expect(bloc.state.people.length, 21);
      expect(bloc.state.hasReachedMax, isTrue);
    },
  );

  for (final succeeds in [true, false]) {
    test(
      'Acknowledgement ${succeeds ? 'success' : 'failure'} uses the viewed version and prevents duplicate requests',
      () async {
        final repository = BoardRepositoryFake();
        final bus = GlobalEventBus();
        final updates = <GlobalEvent>[];
        final subscription = bus.stream.listen(updates.add);
        final bloc = PostDetailBloc(
          getPostDetailUsecase: GetPostDetailUsecase(
            postRepository: repository,
          ),
          toggleLikeUsecase: ToggleLikeUsecase(postRepository: repository),
          globalEventBus: bus,
          deletePostUsecase: DeletePostUsecase(postRepository: repository),
          deletePostFolderUsecase: DeletePostFolderUsecase(
            postRepository: repository,
          ),
          acknowledgePostUsecase: AcknowledgePostUsecase(
            postRepository: repository,
          ),
        );
        addTearDown(() async {
          await bloc.close();
          await subscription.cancel();
          bus.dispose();
        });
        bloc.add(const PostDetailFetched(postId: 'post'));
        await settleEvents();
        bloc.add(const PostDetailAcknowledged());
        bloc.add(const PostDetailAcknowledged());
        await settleEvents();
        expect(repository.acknowledgementCalls, 1);
        expect(repository.acknowledgedVersion, 3);
        expect(bloc.state.post!.currentUserAcknowledged, isFalse);
        repository.acknowledgement.complete(
          succeeds
              ? Right(makePost('post').copyWith(currentUserAcknowledged: true))
              : const Left(ServerFailure(message: 'Nội dung đã thay đổi.')),
        );
        await settleEvents();
        expect(bloc.state.isAcknowledging, isFalse);
        expect(bloc.state.post!.currentUserAcknowledged, succeeds);
        expect(
          updates.whereType<PostUpdateDispatched>().length,
          succeeds ? 1 : 0,
        );
        if (!succeeds) expect(bloc.state.transientFailure, isNotNull);
      },
    );
  }

  test(
    'JSON model reads board metadata and gives old records safe defaults',
    () {
      final json = <String, dynamic>{
        'post_id': 'post',
        'title': 'Title',
        'content': 'Content',
        'post_created_at': '2026-10-20T00:00:00Z',
        'post_updated_at': '2026-10-20T00:00:00Z',
        'author_id': 'admin',
        'author_username': 'Admin',
        'author_role': 'admin',
        'likes_count': 2,
        'comments_count': 1,
        'current_user_liked': false,
      };
      expect(
        PostDisplayModel.fromJson(json).category,
        PostCategories.announcement,
      );
      final post = PostDisplayModel.fromJson({
        ...json,
        'category': 'policy',
        'is_pinned': true,
        'requires_acknowledgement': true,
        'current_user_acknowledged': true,
        'acknowledgements_count': 12,
        'content_version': 4,
      });
      expect(post.isPinned, isTrue);
      expect(post.currentUserAcknowledged, isTrue);
      expect(post.acknowledgementsCount, 12);
      expect(post.contentVersion, 4);
    },
  );
}
