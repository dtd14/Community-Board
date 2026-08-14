import 'package:core/errors.dart';
import 'package:core/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../../../post.dart';
import '../repositories/search_repository.dart';

class SearchPostUsecase implements UsecaseInterface<List<PostDisplay>, String> {
  const SearchPostUsecase({required this._searchRepository});

  final SearchRepository _searchRepository;

  @override
  Future<Either<Failures, List<PostDisplay>>> call(String params) async {
    return await _searchRepository.searchPosts(query: params);
  }
}
