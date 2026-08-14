import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../repositories/repositories.dart';

class SearchUsersUsecase implements UsecaseInterface {
  const SearchUsersUsecase({required this._searchRepository});

  final SearchRepository _searchRepository;

  @override
  Future<Either<Failures, dynamic>> call(params) async {
    return await _searchRepository.searchUsers(query: params);
  }
}
