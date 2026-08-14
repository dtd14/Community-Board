import 'package:core/errors.dart';
import 'package:domain/search.dart';
import 'package:domain/auth.dart';
import 'package:domain/post.dart';
import 'package:fpdart/fpdart.dart';

import '../datasources/datasources.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl({required this._searchRemoteDataSource});
  final SearchRemoteDataSource _searchRemoteDataSource;

  @override
  Future<Either<Failures, List<PostDisplay>>> searchPosts({
    required String query,
  }) async {
    try {
      final posts = await _searchRemoteDataSource.searchPosts(query: query);
      return Right(posts);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failures, List<UserEntity>>> searchUsers({
    required String query,
  }) async {
    try {
      final users = await _searchRemoteDataSource.searchUsers(query: query);
      return Right(users);
    } on NotFountException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissonException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnknownException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
