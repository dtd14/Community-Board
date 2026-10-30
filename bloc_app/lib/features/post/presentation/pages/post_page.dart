import 'package:core/constants.dart';
import 'package:core/utils.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../bloc/post_list/post_list_bloc.dart';
import '../widgets/post_badges.dart';
import '../widgets/post_card.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});
  @override
  Widget build(BuildContext context) => const PostsView();
}

class PostsView extends StatefulWidget {
  const PostsView({super.key});
  @override
  State<PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends State<PostsView> {
  final _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      context.read<PostListBloc>().add(PostListNextPageFetched());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bloc = context.read<PostListBloc>();
    final completed = bloc.stream.firstWhere(
      (s) =>
          s.status == PostListStatus.loaded ||
          s.status == PostListStatus.failure,
    );
    bloc.add(PostListRefreshed());
    await completed;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthenticationBloc bloc) => bloc.state.user);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('Community Board', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            onPressed: () => context.goNamed(RouteNames.search),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: user?.role == Roles.admin
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(RouteNames.postCreate),
              icon: const Icon(Icons.edit_square),
              label: const Text('Đăng bài'),
            )
          : null,
      body: BlocConsumer<PostListBloc, PostListState>(
        listenWhen: (previous, current) =>
            previous.transientFailure != current.transientFailure ||
            previous.scrollToTopEventId != current.scrollToTopEventId,
        listener: (context, state) {
          final bloc = context.read<PostListBloc>();
          if (state.transientFailure != null) {
            showErrorSnackbar(
              context,
              message: state.transientFailure!.message,
            );
            bloc.add(PostListTransientFailureConsumed());
          }
          if (state.scrollToTopEventId != null) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
            bloc.add(PostListEventScrollConsumed());
          }
        },
        builder: (context, state) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'KẾT NỐI NỘI BỘ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      letterSpacing: 2,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Chào ${user?.username.isNotEmpty == true ? user!.username : 'bạn'},',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cùng cập nhật. Cùng kết nối.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Thông báo, quy định và những câu chuyện trong doanh nghiệp.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bảng tin nội bộ',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: state.category == null,
                                onSelected: (_) => context
                                    .read<PostListBloc>()
                                    .add(const PostListCategoryChanged()),
                              ),
                              for (final category in PostCategories.values)
                                ChoiceChip(
                                  avatar: Icon(
                                    postCategoryIcon(category),
                                    size: 17,
                                  ),
                                  label: Text(postCategoryLabel(category)),
                                  selected: state.category == category,
                                  onSelected: (_) =>
                                      context.read<PostListBloc>().add(
                                        PostListCategoryChanged(
                                          category: category,
                                        ),
                                      ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (state.status == PostListStatus.initial ||
                      state.status == PostListStatus.loading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (state.status == PostListStatus.failure)
                    SliverToBoxAdapter(
                      child: _emptyState(
                        Icons.cloud_off_outlined,
                        'Chưa thể tải bảng tin',
                        state.failure?.message ?? 'Vui lòng thử lại.',
                        action: FilledButton(
                          onPressed: () => context.read<PostListBloc>().add(
                            PostListFetched(),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ),
                    )
                  else if (state.posts.isEmpty)
                    SliverToBoxAdapter(
                      child: _emptyState(
                        Icons.forum_outlined,
                        'Chưa có bài viết',
                        'Các thông tin trong mục này sẽ xuất hiện tại đây.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: state.posts.length,
                        itemBuilder: (context, index) => PostCard(
                          post: state.posts[index],
                          onToggleLike: () => context.read<PostListBloc>().add(
                            PostLikeToggled(post: state.posts[index]),
                          ),
                        ),
                      ),
                    ),
                  if (state.status == PostListStatus.fetchingNextPage)
                    const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == PostListStatus.loaded &&
                      !state.hasReachedMax &&
                      state.posts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: TextButton(
                          onPressed: () => context.read<PostListBloc>().add(
                            PostListNextPageFetched(),
                          ),
                          child: const Text('Xem thêm bài viết'),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(
    IconData icon,
    String title,
    String message, {
    Widget? action,
  }) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(icon, size: 48, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.mutedText),
        ),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );
}
