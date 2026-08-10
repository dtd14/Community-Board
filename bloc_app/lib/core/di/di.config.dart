// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:data_supabase/auth.dart' as _i561;
import 'package:data_supabase/post.dart' as _i816;
import 'package:domain/auth.dart' as _i378;
import 'package:domain/post.dart' as _i456;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/auth/presentation/bloc/authentication/authentication_bloc.dart'
    as _i226;
import '../../features/auth/presentation/bloc/login/login_bloc.dart' as _i208;
import '../../features/auth/presentation/bloc/signup/signup_bloc.dart' as _i173;
import '../../features/post/presentation/bloc/post_form/post_form_bloc.dart'
    as _i686;
import '../../features/post/presentation/bloc/post_list/post_list_bloc.dart'
    as _i293;
import '../bus/global_event_bus.dart' as _i91;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule(this);
    gh.singleton<_i91.GlobalEventBus>(
      () => _i91.GlobalEventBus(),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i561.AuthRemoteDataSource>(
      () => registerModule.authRemoteDataSource,
    );
    gh.lazySingleton<_i816.PostRemoteDataSource>(
      () => registerModule.postRemoteDataSource,
    );
    gh.lazySingleton<_i378.AuthRepository>(() => registerModule.authRepository);
    gh.lazySingleton<_i456.PostRepository>(() => registerModule.postRepository);
    gh.factory<_i378.SignupUsecase>(() => registerModule.signupUsecase);
    gh.factory<_i378.LoginUsecase>(() => registerModule.loginUsecase);
    gh.factory<_i378.LogoutUsecase>(() => registerModule.logoutUsecase);
    gh.factory<_i173.SignupBloc>(
      () => _i173.SignupBloc(signupUsecase: gh<_i378.SignupUsecase>()),
    );
    gh.singleton<_i226.AuthenticationBloc>(
      () => _i226.AuthenticationBloc(
        authRepository: gh<_i378.AuthRepository>(),
        logoutUsecase: gh<_i378.LogoutUsecase>(),
      ),
      dispose: (i) => i.close(),
    );
    gh.factory<_i456.GetPostsUsecase>(() => registerModule.getPostUseCase);
    gh.factory<_i456.CreatePostUsecase>(() => registerModule.createPostUsecase);
    gh.factory<_i456.UploadPostImageUsecase>(
      () => registerModule.uploadPostImageUsecase,
    );
    gh.factory<_i293.PostListBloc>(
      () => _i293.PostListBloc(
        getPostsUsecase: gh<_i456.GetPostsUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
      ),
    );
    gh.singleton<_i583.GoRouter>(
      () => registerModule.router(gh<_i226.AuthenticationBloc>()),
    );
    gh.factory<_i208.LoginBloc>(
      () => _i208.LoginBloc(loginUsecase: gh<_i378.LoginUsecase>()),
    );
    gh.factory<_i686.PostFormBloc>(
      () => _i686.PostFormBloc(
        createPostUsecase: gh<_i456.CreatePostUsecase>(),
        uploadPostImageUsecase: gh<_i456.UploadPostImageUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {
  _$RegisterModule(this._getIt);

  final _i174.GetIt _getIt;

  @override
  _i561.SupabaseAuthRemoteDataSource get authRemoteDataSource =>
      _i561.SupabaseAuthRemoteDataSource(
        supabaseClient: _getIt<_i454.SupabaseClient>(),
      );

  @override
  _i816.SupabasePostRemoteDataSource get postRemoteDataSource =>
      _i816.SupabasePostRemoteDataSource(
        supabaseClient: _getIt<_i454.SupabaseClient>(),
      );

  @override
  _i561.AuthRepositoryImpl get authRepository => _i561.AuthRepositoryImpl(
    authRomoteDataSource: _getIt<_i561.AuthRemoteDataSource>(),
  );

  @override
  _i816.PostRepositoryImpl get postRepository => _i816.PostRepositoryImpl(
    postRemoteDataSource: _getIt<_i816.PostRemoteDataSource>(),
  );

  @override
  _i378.SignupUsecase get signupUsecase =>
      _i378.SignupUsecase(authRepository: _getIt<_i378.AuthRepository>());

  @override
  _i378.LoginUsecase get loginUsecase =>
      _i378.LoginUsecase(authRepository: _getIt<_i378.AuthRepository>());

  @override
  _i378.LogoutUsecase get logoutUsecase =>
      _i378.LogoutUsecase(authRepository: _getIt<_i378.AuthRepository>());

  @override
  _i456.GetPostsUsecase get getPostUseCase =>
      _i456.GetPostsUsecase(postRepository: _getIt<_i456.PostRepository>());

  @override
  _i456.CreatePostUsecase get createPostUsecase =>
      _i456.CreatePostUsecase(postRepository: _getIt<_i456.PostRepository>());

  @override
  _i456.UploadPostImageUsecase get uploadPostImageUsecase =>
      _i456.UploadPostImageUsecase(
        postRepository: _getIt<_i456.PostRepository>(),
      );
}
