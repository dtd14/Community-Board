import '../../../auth.dart';
import '../../../post.dart';

abstract interface class SearchRemoteDataSource {
  Future<List<PostDisplayModel>> searchPosts({required String query});

  Future<List<UserModel>> searchUsers({required String query});
}
