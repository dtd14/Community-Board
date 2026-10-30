import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../../features/post/presentation/bloc/post_list/post_list_bloc.dart';
import '../blocs/realtime/realtime_bloc.dart';
import '../theme/app_colors.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context) {
    return BlocListener<RealtimeBloc, RealtimeState>(
      listener: (context, state) {
        if (state is RealtimeNewPostArrived) {
          final currentUserId = context
              .read<AuthenticationBloc>()
              .state
              .user
              ?.id;
          final newPost = state.post;

          if (newPost.authorId != currentUserId) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: const Text('Có bài viết mới trên bảng tin'),
                  action: SnackBarAction(
                    label: 'Cập nhật',
                    onPressed: () {
                      context.read<PostListBloc>().add(
                        PostListNewPostPrepended(post: newPost),
                      );
                      context.read<PostListBloc>().add(PostListScrollToTop());
                    },
                  ),
                ),
              );
          }
          context.read<RealtimeBloc>().add(const RealtimeStateResetRequested());
        }
        if (state is RealtimeConnectionFailure) {
          showErrorSnackbar(
            context,
            message: 'Realtime Error: ${state.message}',
          );
          context.read<RealtimeBloc>().add(const RealtimeStateResetRequested());
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          void select(int index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
          final wide = constraints.maxWidth >= 900;
          return Scaffold(
            body: Row(
              children: [
                if (wide) ...[
                  NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: select,
                    backgroundColor: Colors.white,
                    indicatorColor: AppColors.primarySoft,
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Icon(
                        Icons.hub_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Bảng tin'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search),
                        label: Text('Tìm kiếm'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Cá nhân'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: navigationShell),
              ],
            ),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: select,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Bảng tin',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.search),
                        label: 'Tìm kiếm',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Cá nhân',
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
