import 'dart:async';

import 'package:core/errors.dart';
import 'package:domain/post.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';

class RealtimeRepositoryImpl implements RealtimeRepository {
  const RealtimeRepositoryImpl({
    required this._realtimeRemoteDataSource,
    required this._postRemoteDataSource,
  });

  final RealtimeRemoteDataSource _realtimeRemoteDataSource;
  final PostRemoteDataSource _postRemoteDataSource;

  @override
  Stream<Either<Failures, PostDisplay>> get newPostStream {
    final transformer =
        StreamTransformer<String, Either<Failures, PostDisplay>>.fromHandlers(
          handleData:
              (
                String postId,
                EventSink<Either<Failures, PostDisplay>> sink,
              ) async {
                try {
                  final postModel = await _postRemoteDataSource.getPostDetail(
                    postId: postId,
                  );
                  sink.add(Right(postModel));
                } on AppException catch (e) {
                  sink.add(Left(ServerFailure(message: e.toString())));
                }
              },
          handleError:
              (
                Object error,
                StackTrace stacktrace,
                EventSink<Either<Failures, PostDisplay>> sink,
              ) {
                sink.add(Left(ConnectionFailure(message: error.toString())));
              },
        );

    return _realtimeRemoteDataSource.newPostIdStream.transform(transformer);
  }

  @override
  Future<void> disconnect() async {
    await _realtimeRemoteDataSource.disconnect();
  }
}
