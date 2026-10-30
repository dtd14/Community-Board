import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../bloc/post_people/post_people_bloc.dart';

Future<void> showPostPeopleSheet(
  BuildContext context, {
  required String postId,
  PostPeopleKind kind = PostPeopleKind.likes,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<PostPeopleBloc>()
            ..add(PostPeopleFetched(postId: postId, kind: kind)),
      child: const _PostPeopleSheet(),
    ),
  );
}

class _PostPeopleSheet extends StatelessWidget {
  const _PostPeopleSheet();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .72,
    child: BlocBuilder<PostPeopleBloc, PostPeopleState>(
      builder: (context, state) {
        final bloc = context.read<PostPeopleBloc>();
        final isLikes = state.kind == PostPeopleKind.likes;
        void reload() =>
            bloc.add(PostPeopleFetched(postId: state.postId, kind: state.kind));
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isLikes ? 'Người thích bài viết' : 'Tình hình xác nhận',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: reload,
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Đóng',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (!isLikes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final kind in [
                      PostPeopleKind.acknowledged,
                      PostPeopleKind.pending,
                    ])
                      ChoiceChip(
                        label: Text(
                          kind == PostPeopleKind.acknowledged
                              ? 'Đã xác nhận'
                              : 'Chưa xác nhận',
                        ),
                        selected: state.kind == kind,
                        onSelected: (_) => bloc.add(
                          PostPeopleFetched(postId: state.postId, kind: kind),
                        ),
                      ),
                  ],
                ),
              ),
            if (state.status == PostPeopleStatus.loaded ||
                state.status == PostPeopleStatus.loadingMore)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${state.totalCount} người',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: switch (state.status) {
                PostPeopleStatus.initial || PostPeopleStatus.loading =>
                  const Center(child: CircularProgressIndicator()),
                PostPeopleStatus.failure => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.failure?.message ?? 'Không thể tải danh sách.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: reload,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
                _ =>
                  state.people.isEmpty
                      ? Center(
                          child: Text(
                            isLikes
                                ? 'Chưa có lượt thích nào.'
                                : 'Không có nhân viên trong danh sách này.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: state.people.length + 1,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 64),
                          itemBuilder: (context, index) {
                            if (index == state.people.length) {
                              if (state.status ==
                                  PostPeopleStatus.loadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (state.hasReachedMax) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  if (state.failure != null)
                                    Text(state.failure!.message),
                                  TextButton(
                                    onPressed: () =>
                                        bloc.add(PostPeopleNextPageFetched()),
                                    child: Text(
                                      state.failure == null
                                          ? 'Xem thêm'
                                          : 'Thử lại',
                                    ),
                                  ),
                                ],
                              );
                            }
                            final person = state.people[index];
                            return ListTile(
                              leading: UserAvatar(
                                name: person.username,
                                imageUrl: person.avatarUrl,
                              ),
                              title: Text(person.username),
                              subtitle: person.acknowledgedAt == null
                                  ? null
                                  : Text(
                                      'Xác nhận lúc ${DateFormat('dd/MM/yyyy HH:mm').format(person.acknowledgedAt!.toLocal())}',
                                    ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                final router = GoRouter.of(context);
                                Navigator.pop(context);
                                router.pushNamed(
                                  RouteNames.userDetail,
                                  pathParameters: {'userId': person.userId},
                                );
                              },
                            );
                          },
                        ),
              },
            ),
          ],
        );
      },
    ),
  );
}
