import 'dart:io';

import 'package:core/constants.dart';
import 'package:core/errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/models/user_model.dart';
import '../../post/models/post_display_model.dart';
import 'search_remote_data_source.dart';

class SupabaseSearchRemoteDataSource implements SearchRemoteDataSource {
  const SupabaseSearchRemoteDataSource({required this._supabaseClient});

  final SupabaseClient _supabaseClient;

  @override
  Future<List<PostDisplayModel>> searchPosts({required String query}) async {
    try {
      if (_supabaseClient.auth.currentUser == null) {
        throw const AuthenticationException(
          message: 'User is not authenticated',
        );
      }

      final result = await _supabaseClient.rpc(
        DBFunctions.searchPosts,
        params: {'p_search_query': query},
      );
      final searchMap = List<Map<String, dynamic>>.from(result as List);
      return searchMap.map((json) => PostDisplayModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      if (e.code == PostgresError.insufficientPrivilege) {
        throw PermissonException(message: e.message);
      }
      if (e.code == PostgresError.moreThenOneOrNoItemsReturned) {
        throw NotFountException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<List<UserModel>> searchUsers({required String query}) async {
    try {
      if (_supabaseClient.auth.currentUser == null) {
        throw const AuthenticationException(
          message: 'User is not authenticated',
        );
      }

      final response = await _supabaseClient
          .from(Tables.profiles)
          .select()
          .ilike('username', '%$query%')
          .limit(10);

      return response.map((json) => UserModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      if (e.code == PostgresError.insufficientPrivilege) {
        throw PermissonException(message: e.message);
      }
      if (e.code == PostgresError.moreThenOneOrNoItemsReturned) {
        throw NotFountException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}
