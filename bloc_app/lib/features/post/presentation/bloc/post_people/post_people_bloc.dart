import 'package:bloc/bloc.dart';
import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'post_people_event.dart';
part 'post_people_state.dart';

@injectable
class PostPeopleBloc extends Bloc<PostPeopleEvent, PostPeopleState> {
  PostPeopleBloc({required this.getPostPeopleUsecase})
    : super(const PostPeopleState()) {
    on<PostPeopleFetched>(_onFetched);
    on<PostPeopleNextPageFetched>(_onNextPage);
  }
  final GetPostPeopleUsecase getPostPeopleUsecase;
  static const _pageSize = 20;
  int _requestId = 0;
  int _nextOffset = 0;

  Future<void> _onFetched(
    PostPeopleFetched event,
    Emitter<PostPeopleState> emit,
  ) async {
    final requestId = ++_requestId;
    _nextOffset = 0;
    emit(
      PostPeopleState(
        status: PostPeopleStatus.loading,
        postId: event.postId,
        kind: event.kind,
      ),
    );
    final result = await getPostPeopleUsecase(
      GetPostPeopleParams(
        postId: event.postId,
        kind: event.kind,
        limit: _pageSize,
      ),
    );
    if (requestId != _requestId || emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PostPeopleStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) {
        _nextOffset = page.people.length;
        emit(
          state.copyWith(
            status: PostPeopleStatus.loaded,
            people: page.people,
            totalCount: page.totalCount,
            hasReachedMax:
                page.people.length < _pageSize ||
                _nextOffset >= page.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onNextPage(
    PostPeopleNextPageFetched event,
    Emitter<PostPeopleState> emit,
  ) async {
    if (state.status != PostPeopleStatus.loaded || state.hasReachedMax) return;
    final requestId = _requestId;
    emit(
      state.copyWith(status: PostPeopleStatus.loadingMore, failure: () => null),
    );
    final result = await getPostPeopleUsecase(
      GetPostPeopleParams(
        postId: state.postId,
        kind: state.kind,
        offset: _nextOffset,
        limit: _pageSize,
      ),
    );
    if (requestId != _requestId || emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: PostPeopleStatus.loaded, failure: () => failure),
      ),
      (page) {
        _nextOffset += page.people.length;
        final people = {
          for (final person in state.people) person.userId: person,
        };
        for (final person in page.people) {
          people[person.userId] = person;
        }
        emit(
          state.copyWith(
            status: PostPeopleStatus.loaded,
            people: people.values.toList(),
            totalCount: page.totalCount,
            hasReachedMax:
                page.people.length < _pageSize ||
                _nextOffset >= page.totalCount,
          ),
        );
      },
    );
  }
}
