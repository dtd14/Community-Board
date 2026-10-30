import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/constants.dart';
import 'package:core/utils.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/post_badges.dart';
import '../widgets/post_people_sheet.dart';
import '../../../auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../bloc/comments_list/comments_list_bloc.dart';
import '../bloc/post_detail/post_detail_bloc.dart';
import '../widgets/comment_input_field.dart';
import '../widgets/comment_list_view.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (content) =>
              getIt<PostDetailBloc>()..add(PostDetailFetched(postId: postId)),
        ),
        BlocProvider(
          create: (context) =>
              getIt<CommentsListBloc>()
                ..add(CommentListFetched(postId: postId)),
        ),
      ],
      child: BlocListener<PostDetailBloc, PostDetailState>(
        listenWhen: (previous, current) {
          final didDelete =
              !previous.deletionSuccess && current.deletionSuccess;
          final didFail =
              previous.transientFailure == null &&
              current.transientFailure != null;
          return didFail || didDelete;
        },
        listener: (context, state) {
          if (state.deletionSuccess) {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) navigator.pop();
            if (navigator.canPop()) navigator.pop();
            return;
          }

          if (state.transientFailure != null) {
            showErrorSnackbar(
              context,
              message: state.transientFailure!.message,
            );
            context.read<PostDetailBloc>().add(
              PostDetailTransientFailureComsumed(),
            );
          }
        },
        child: PostDetailView(postId: postId),
      ),
    );
  }
}

class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key, required this.postId});
  final String postId;

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CommentsListBloc>().add(
        CommentListNextPageFetched(postId: widget.postId),
      );
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final postDetailBloc = context.read<PostDetailBloc>();

    showDialog(
      context: context,
      builder: (context) {
        return BlocProvider.value(
          value: postDetailBloc,
          child: BlocBuilder<PostDetailBloc, PostDetailState>(
            builder: (context, state) {
              final isSubmitting = state.status == PostDetailStatus.submitting;
              return PopScope(
                canPop: !isSubmitting,
                child: AlertDialog(
                  title: const Text('Xóa bài viết'),
                  content: const Text('Bạn có chắc muốn xóa bài viết này?'),
                  actions: [
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              postDetailBloc.add(const PostDeleted());
                            },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xóa'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      barrierDismissible:
          postDetailBloc.state.status != PostDetailStatus.submitting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select(
      (AuthenticationBloc bloc) => bloc.state.user,
    );
    final currentUserRole = currentUser?.role;
    return BlocBuilder<PostDetailBloc, PostDetailState>(
      builder: (context, state) {
        switch (state.status) {
          case PostDetailStatus.initial || PostDetailStatus.loading:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          case PostDetailStatus.failure:
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Error: ${state.failure?.message ?? 'Unknown error'}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          case _:
            final post = state.post!;
            final canModify =
                (currentUser?.id == post.authorId) &&
                (currentUserRole == Roles.admin);
            return Scaffold(
              appBar: AppBar(
                title: const Text('Chi tiết bài viết'),
                actions: [
                  if (canModify)
                    IconButton(
                      onPressed: () {
                        context.pushNamed(
                          RouteNames.postEdit,
                          pathParameters: {'postId': post.postId},
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Chỉnh sửa',
                    ),
                  if (canModify)
                    IconButton(
                      onPressed: () {
                        _showDeleteConfirmDialog(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Xóa bài viết',
                    ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    children: [
                      Expanded(child: _buildContext(context, post)),
                      CommentInputField(
                        postId: widget.postId,
                        scrollController: _scrollController,
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
  }

  Widget _buildContext(BuildContext context, PostDisplay post) {
    return BlocListener<CommentsListBloc, CommentsListState>(
      listenWhen: ((previous, current) {
        final prevTransientFailure = previous.transientFailure;
        final currentTransientFailure = current.transientFailure;
        final isTransientFailure =
            prevTransientFailure == null || currentTransientFailure != null;

        return isTransientFailure;
      }),
      listener: (context, state) {
        if (state.transientFailure != null) {
          showErrorSnackbar(context, message: state.transientFailure!.message);
          context.read<CommentsListBloc>().add(
            CommentListTrasientFailureConsumed(),
          );
        }
      },

      child: RefreshIndicator(
        onRefresh: () async {
          context.read<PostDetailBloc>().add(
            PostDetailFetched(postId: widget.postId),
          );
          context.read<CommentsListBloc>().add(
            CommentListFetched(postId: widget.postId),
          );
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent:
                BouncingScrollPhysics(), // Giúp có độ nảy để dễ chạm ngưỡng maxScrollExtent
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildPostDetail(context, post)),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            const SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: CommentListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcknowledgement(BuildContext context, PostDisplay post) {
    final user = context.read<AuthenticationBloc>().state.user;
    final state = context.watch<PostDetailBloc>().state;
    final isAuthor = user?.id == post.authorId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                post.currentUserAcknowledged
                    ? Icons.task_alt
                    : Icons.fact_check_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.currentUserAcknowledged
                      ? 'Bạn đã xác nhận đã đọc'
                      : 'Thông tin cần xác nhận',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAuthor
                ? 'Theo dõi việc tiếp nhận thông tin của các thành viên.'
                : 'Sau khi đọc nội dung, hãy xác nhận để người phụ trách biết bạn đã tiếp nhận.',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 14),
          if (!isAuthor && user != null)
            FilledButton.icon(
              onPressed:
                  post.currentUserAcknowledged ||
                      state.isAcknowledging ||
                      state.isLiking
                  ? null
                  : () => context.read<PostDetailBloc>().add(
                      const PostDetailAcknowledged(),
                    ),
              icon: state.isAcknowledging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all, size: 18),
              label: Text(
                post.currentUserAcknowledged ? 'Đã xác nhận' : 'Tôi đã đọc',
              ),
            ),
          if (user?.role == Roles.admin)
            TextButton.icon(
              onPressed: () => showPostPeopleSheet(
                context,
                postId: post.postId,
                kind: PostPeopleKind.acknowledged,
              ),
              icon: const Icon(Icons.people_outline),
              label: Text(
                '${post.acknowledgementsCount} người đã xác nhận · Xem danh sách',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostDetail(BuildContext context, PostDisplay post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  final currentUserId = context
                      .read<AuthenticationBloc>()
                      .state
                      .user
                      ?.id;
                  if (currentUserId != post.authorId) {
                    context.pushNamed(
                      RouteNames.userDetail,
                      pathParameters: {'userId': post.authorId},
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  child:
                      post.authorAvatarUrl == null ||
                          post.authorAvatarUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: post.authorAvatarUrl!,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error_outline, size: 22),
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat(
                        'yyyy-MM-dd HH:mm',
                      ).format(post.postCreatedAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PostBadges(post: post),
          const SizedBox(height: 16),
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),

          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                placeholder: (context, url) => AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(color: Colors.grey.shade200),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported_outlined),
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            post.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: post.currentUserLiked ? 'Bỏ thích' : 'Thích bài viết',
                onPressed:
                    context.select(
                      (PostDetailBloc bloc) =>
                          bloc.state.isLiking || bloc.state.isAcknowledging,
                    )
                    ? null
                    : () => context.read<PostDetailBloc>().add(
                        const PostDetailLikeToggled(),
                      ),
                icon: Icon(
                  post.currentUserLiked
                      ? Icons.thumb_up
                      : Icons.thumb_up_alt_outlined,
                ),
                color: post.currentUserLiked
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              TextButton(
                onPressed: () =>
                    showPostPeopleSheet(context, postId: post.postId),
                child: Text('${post.likesCount} lượt thích'),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.mode_comment_outlined, size: 24),
              const SizedBox(width: 12),
              Text(post.commentsCount.toString()),
            ],
          ),
          if (post.requiresAcknowledgement) ...[
            const SizedBox(height: 20),
            _buildAcknowledgement(context, post),
          ],
          const SizedBox(height: 16),
          Text(
            'Trao đổi & phản hồi',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
