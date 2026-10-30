import 'dart:io';
import 'dart:ui' as ui;

import 'package:domain/auth.dart';
import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_app/core/theme/app_theme.dart';
import 'package:bloc_app/core/config/router/app_router.dart';
import 'package:bloc_app/core/blocs/realtime/realtime_bloc.dart';
import 'package:bloc_app/features/auth/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:bloc_app/features/auth/presentation/widgets/auth_header.dart';
import 'package:bloc_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:bloc_app/features/post/presentation/bloc/comments_list/comments_list_bloc.dart';
import 'package:bloc_app/features/post/presentation/bloc/post_detail/post_detail_bloc.dart';
import 'package:bloc_app/features/post/presentation/bloc/post_form/post_form_bloc.dart';
import 'package:bloc_app/features/post/presentation/bloc/post_list/post_list_bloc.dart';
import 'package:bloc_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:bloc_app/features/post/presentation/pages/post_form_page.dart';
import 'package:bloc_app/features/post/presentation/pages/post_page.dart';

class _Auth extends Fake implements AuthenticationBloc {
  _Auth({this.admin = false});
  final bool admin;
  @override
  AuthenticationState get state => AuthenticationState.authenticated(
    UserEntity(
      id: admin ? 'admin' : 'member',
      username: 'Minh Anh',
      role: admin ? 'admin' : 'user',
    ),
  );
  @override
  Stream<AuthenticationState> get stream => const Stream.empty();
}

PostDisplay _post() => PostDisplay(
  postId: 'demo',
  title: 'Cùng xây dựng môi trường làm việc an toàn',
  content:
      'Quy định bảo mật thông tin đã được cập nhật. Mời các thành viên đọc nội dung và xác nhận đã tiếp nhận trước buổi trao đổi chung của công ty.',
  postCreatedAt: DateTime(2026, 10, 20, 9),
  postUpdatedAt: DateTime(2026, 10, 20, 9),
  authorId: 'admin',
  authorUsername: 'Phòng Nhân sự',
  authorRole: 'admin',
  likesCount: 12,
  commentsCount: 4,
  currentUserLiked: false,
  category: PostCategories.policy,
  isPinned: true,
  requiresAcknowledgement: true,
);

class _Feed extends Fake implements PostListBloc {
  @override
  PostListState get state => PostListState(
    status: PostListStatus.loaded,
    posts: [_post()],
    hasReachedMax: true,
  );
  @override
  Stream<PostListState> get stream => const Stream.empty();
  @override
  void add(PostListEvent event) {}
}

class _Realtime extends Fake implements RealtimeBloc {
  @override
  RealtimeState get state => const RealtimeInitial();
  @override
  Stream<RealtimeState> get stream => const Stream.empty();
  @override
  void add(RealtimeEvent event) {}
}

class _Detail extends Fake implements PostDetailBloc {
  final events = <PostDetailEvent>[];
  @override
  PostDetailState get state =>
      PostDetailState(status: PostDetailStatus.loaded, post: _post());
  @override
  Stream<PostDetailState> get stream => const Stream.empty();
  @override
  void add(PostDetailEvent event) => events.add(event);
}

class _Comments extends Fake implements CommentsListBloc {
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

class _Form extends Fake implements PostFormBloc {
  _Form({this.current = const PostFormInitial()});
  final PostFormState current;
  final events = <PostFormEvent>[];
  @override
  PostFormState get state => current;
  @override
  Stream<PostFormState> get stream => const Stream.empty();
  @override
  void add(PostFormEvent event) => events.add(event);
}

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget child, {bool admin = false, double scale = 1}) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationBloc>.value(value: _Auth(admin: admin)),
        BlocProvider<PostListBloc>.value(value: _Feed()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      ),
    );

void main() {
  const previews = bool.fromEnvironment('WRITE_PREVIEWS');
  if (previews) {
    setUpAll(() async {
      // Optional local preview export; normal tests have no system-font dependency.
      final file = File('C:/Windows/Fonts/segoeui.ttf');
      if (await file.exists()) {
        for (final family in ['Roboto', 'Ahem']) {
          final loader = FontLoader(family);
          loader.addFont(
            file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
          await loader.load();
        }
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
  }

  for (final size in [const Size(390, 844), const Size(1440, 900)]) {
    testWidgets(
      'Feed fits ${size.width.toInt()}px and exposes category filters',
      (tester) async {
        await _size(tester, size);
        final key = GlobalKey();
        final auth = _Auth(admin: true);
        final router = createRouter(auth);
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthenticationBloc>.value(value: auth),
              BlocProvider<PostListBloc>.value(value: _Feed()),
              BlocProvider<RealtimeBloc>.value(value: _Realtime()),
            ],
            child: RepaintBoundary(
              key: key,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Bảng tin nội bộ'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, 'Quy định'), findsOneWidget);
        expect(
          find.byType(size.width >= 900 ? NavigationRail : NavigationBar),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (previews) {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('docs/ui-preview/feed-${size.width.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }

  testWidgets(
    'Failed edit loading offers retry without becoming a create form',
    (tester) async {
      final bloc = _Form(
        current: const PostFormLoadFailure(
          failure: ServerFailure(message: 'Không tải được bài viết.'),
        ),
      );
      await tester.pumpWidget(
        _app(
          BlocProvider<PostFormBloc>.value(
            value: bloc,
            child: const PostFormView(isEditMode: true, postId: 'existing'),
          ),
          admin: true,
        ),
      );
      expect(find.text('Không tải được bài viết.'), findsOneWidget);
      expect(find.text('Đăng bài viết'), findsNothing);
      await tester.tap(find.text('Thử lại'));
      expect(
        bloc.events.whereType<PostFormPrefilled>().single.postId,
        'existing',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Narrow feed supports enlarged text without overflow', (
    tester,
  ) async {
    await _size(tester, const Size(320, 740));
    await tester.pumpWidget(_app(const PostsView(), scale: 1.5));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    // Flutter reports uncaught layout exceptions with the offending widget.
  });

  testWidgets(
    'Employee can explicitly confirm, but cannot see the admin receipt list',
    (tester) async {
      await _size(tester, const Size(390, 844));
      final bloc = _Detail();
      await tester.pumpWidget(
        _app(
          MultiBlocProvider(
            providers: [
              BlocProvider<PostDetailBloc>.value(value: bloc),
              BlocProvider<CommentsListBloc>.value(value: _Comments()),
            ],
            child: const PostDetailView(postId: 'demo'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Tôi đã đọc'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Tôi đã đọc'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tôi đã đọc'));
      expect(bloc.events.whereType<PostDetailAcknowledged>().length, 1);
      expect(find.textContaining('Xem danh sách'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Post form submits category, pin and receipt requirement through the existing event',
    (tester) async {
      await _size(tester, const Size(800, 1200));
      final bloc = _Form();
      await tester.pumpWidget(
        _app(
          BlocProvider<PostFormBloc>.value(
            value: bloc,
            child: const PostFormView(isEditMode: false),
          ),
          admin: true,
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quy định').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Quy định mới');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Nội dung cần xác nhận',
      );
      await tester.ensureVisible(find.text('Ghim bài viết'));
      await tester.tap(find.text('Ghim bài viết'));
      await tester.ensureVisible(find.text('Yêu cầu xác nhận đã đọc'));
      await tester.tap(find.text('Yêu cầu xác nhận đã đọc'));
      await tester.ensureVisible(find.text('Đăng bài viết'));
      await tester.tap(find.text('Đăng bài viết'));
      final event = bloc.events.whereType<PostSubmitted>().single;
      expect(event.category, PostCategories.policy);
      expect(event.isPinned, isTrue);
      expect(event.requiresAcknowledgement, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(390, 700), const Size(1200, 600)]) {
    testWidgets(
      'Authentication layout fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _size(tester, size);
        await tester.pumpWidget(
          _app(
            const AuthLayout(
              child: Column(
                children: [
                  AuthHeader(
                    title: 'Chào mừng trở lại',
                    subtitle: 'Kết nối cùng đồng nghiệp',
                  ),
                  SizedBox(height: 24),
                  TextField(decoration: InputDecoration(labelText: 'Email')),
                  SizedBox(height: 16),
                  TextField(decoration: InputDecoration(labelText: 'Mật khẩu')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
