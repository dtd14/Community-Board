import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/post_list/post_list_bloc.dart';
import '../widgets/post_card.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PostsView();
  }
}

class PostsView extends StatefulWidget {
  const PostsView({super.key});

  @override
  State<PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends State<PostsView> {
  final ScrollController _scrollController = ScrollController();

  static const _pageBg = Color(0xFFE2E5E9);
  static const _ink = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostListBloc>().add(PostListNextPageFetched());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeaderTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 28,
              height: 28,
              color: _ink,
              child: const Icon(
                Icons.forum_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Community Board',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [UI - SỬA] Thêm màu nền cho trang
      backgroundColor: _pageBg,

      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: _buildHeaderTitle(),
      ),
      body: BlocConsumer<PostListBloc, PostListState>(
        listenWhen: (previous, current) {
          final isTransientFailure =
              previous.transientFailure == null &&
              current.transientFailure != null;

          final prevScrollEventId = previous.scrollToTopEventId;
          final currentScrollEventId = current.scrollToTopEventId;
          final isScrollToTopEvent =
              prevScrollEventId != currentScrollEventId &&
              currentScrollEventId != null;
          return isTransientFailure || isScrollToTopEvent;
        },
        listener: (context, state) {
          if (state.scrollToTopEventId != null) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(microseconds: 300),
              curve: Curves.easeOut,
            );
            context.read<PostListBloc>().add(PostListEventScrollConsumed());
          } else if (state.transientFailure != null) {
            showErrorSnackbar(
              context,
              message: state.transientFailure!.message,
            );
          }
          context.read<PostListBloc>().add(PostListTransientFailureConsumed());
        },
        builder: (context, state) {
          switch (state.status) {
            case PostListStatus.initial:
            case PostListStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case PostListStatus.failure:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${state.failure?.message ?? 'Unknown error'}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PostListBloc>().add(PostListFetched());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            case _:
              if (state.posts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<PostListBloc>().add(PostListRefreshed());
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: const Center(
                            child: Text(
                              'There are no posts yet.\nLog in with  an admin account to create your first post!',
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PostListBloc>().add(PostListRefreshed());
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.hasReachedMax
                      ? state.posts.length
                      : state.posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= state.posts.length) {
                      return (state.status == PostListStatus.fetchingNextPage)
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    final post = state.posts[index];
                    return PostCard(
                      post: post,
                      onToggleLike: () {
                        context.read<PostListBloc>().add(
                          PostLikeToggled(post: post),
                        );
                      },
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
