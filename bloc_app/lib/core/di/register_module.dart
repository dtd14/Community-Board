import 'package:data_supabase/auth.dart';
import 'package:data_supabase/post.dart';
import 'package:domain/auth.dart';
import 'package:domain/post.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../config/router/app_router.dart';

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
}
