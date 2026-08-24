import 'dart:async';

import 'package:data_supabase/auth.dart';
import 'package:data_supabase/post.dart';
import 'package:data_supabase/profile.dart';
import 'package:data_supabase/search.dart';
import 'package:domain/auth.dart';
import 'package:domain/post.dart';
import 'package:domain/profile.dart';
import 'package:domain/search.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../config/router/app_router.dart';

FutureOr<void> disposeRealtimeDataSource(RealtimeRemoteDataSource instance) {
  instance.dispose();
}

@module
abstract class RegisterModule {
  @singleton
  SupabaseClient get supabaseClient => Supabase.instance.client;

  @singleton
  GoRouter router(AuthenticationBloc authBloc) => createRouter(authBloc);

  // Data Layer Registration (lazySingleton)
  // auth
  @LazySingleton(as: AuthRemoteDataSource)
  SupabaseAuthRemoteDataSource get authRemoteDataSource;

  @LazySingleton(as: AuthRepository)
  AuthRepositoryImpl get authRepository;

  // post
  @LazySingleton(as: PostRemoteDataSource)
  SupabasePostRemoteDataSource get postRemoteDataSource;

  @LazySingleton(as: PostRepository)
  PostRepositoryImpl get postRepository;

  @LazySingleton(as: RealtimeRemoteDataSource, dispose: disposeRealtimeDataSource)
  SupabaseRealtimeRemoteDataSource get realtimeRemoteDataSource;

  @LazySingleton(as: RealtimeRepository)
  RealtimeRepositoryImpl get realtimeRepository;

  // profile
  @LazySingleton(as: ProfileRemoteDataSource)
  SupabaseProfileRemoteDataSource get profileRemoteDataSource;

  @LazySingleton(as: ProfileRepository)
  ProfileRepositoryImpl get profileRepository;

  // search
  @LazySingleton(as: SearchRemoteDataSource)
  SupabaseSearchRemoteDataSource get searchRemoteDataSource;

  @LazySingleton(as: SearchRepository)
  SearchRepositoryImpl get searchRepository;

  // Domain Layer (UseCases) Registration (Injectable - factory)
  // auth
  @injectable
  SignupUsecase get signupUsecase;

  @injectable
  LoginUsecase get loginUsecase;

  @injectable
  LogoutUsecase get logoutUsecase;

  // post
  @injectable
  GetPostsUsecase get getPostUseCase;

  @injectable
  CreatePostUsecase get createPostUsecase;

  @injectable
  UploadPostImageUsecase get uploadPostImageUsecase;

  @injectable
  GetPostDetailUsecase get getPostDetailUsecase;

  @injectable
  GetCommentsUsecase get getCommentsUsecase;

  @injectable
  ToggleLikeUsecase get toggleLikeUsecase;

  @injectable
  CreateCommentUsecase get createCommentUsecase;

  @injectable
  UpdateCommentUsecase get updateCommentUsecase;

  @injectable
  DeleteCommentUsecase get deleteCommentUsecase;

  @injectable
  DeletePostUsecase get deletePostUsecase;

  @injectable
  DeletePostFolderUsecase get deletePostFolderUsecase;

  @injectable
  UpdatePostUsecase get updatePostUsecase;

  @injectable
  GetMyPostUsecase get getMyPostUsecase;

  // profile
  @injectable
  GetProfileUsecase get getProfileUsecase;

  @injectable
  UpdateProfileUsecase get updateProfileUsecase;

  // search
  @injectable
  SearchPostUsecase get searchPostUsecase;

  @injectable
  SearchUsersUsecase get searchUsersUsecase;
}
