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
import 'package:data_supabase/profile.dart' as _i661;
import 'package:data_supabase/search.dart' as _i66;
import 'package:domain/auth.dart' as _i378;
import 'package:domain/post.dart' as _i456;
import 'package:domain/profile.dart' as _i503;
import 'package:domain/search.dart' as _i93;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/auth/presentation/bloc/authentication/authentication_bloc.dart'
    as _i226;
import '../../features/auth/presentation/bloc/login/login_bloc.dart' as _i208;
import '../../features/auth/presentation/bloc/signup/signup_bloc.dart' as _i173;
import '../../features/post/presentation/bloc/comments_list/comments_list_bloc.dart'
    as _i270;
import '../../features/post/presentation/bloc/my_post_list/my_post_list_bloc.dart'
    as _i150;
import '../../features/post/presentation/bloc/post_detail/post_detail_bloc.dart'
    as _i557;
import '../../features/post/presentation/bloc/post_form/post_form_bloc.dart'
    as _i686;
import '../../features/post/presentation/bloc/post_list/post_list_bloc.dart'
    as _i293;
import '../../features/profile/presentation/blocs/edit_profile/edit_profile_bloc.dart'
    as _i1033;
import '../../features/profile/presentation/blocs/profile/profile_bloc.dart'
    as _i349;
import '../../features/profile/presentation/blocs/user_profile/user_profile_bloc.dart'
    as _i634;
import '../../features/search/presentation/blocs/search/search_bloc.dart'
    as _i608;
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
    gh.lazySingleton<_i66.SearchRemoteDataSource>(
      () => registerModule.searchRemoteDataSource,
    );
    gh.lazySingleton<_i661.ProfileRemoteDataSource>(
      () => registerModule.profileRemoteDataSource,
    );
    gh.lazySingleton<_i378.AuthRepository>(() => registerModule.authRepository);
    gh.lazySingleton<_i456.PostRepository>(() => registerModule.postRepository);
    gh.factory<_i378.SignupUsecase>(() => registerModule.signupUsecase);
    gh.factory<_i378.LoginUsecase>(() => registerModule.loginUsecase);
    gh.factory<_i378.LogoutUsecase>(() => registerModule.logoutUsecase);
    gh.factory<_i173.SignupBloc>(
      () => _i173.SignupBloc(signupUsecase: gh<_i378.SignupUsecase>()),
    );
    gh.lazySingleton<_i93.SearchRepository>(
      () => registerModule.searchRepository,
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
    gh.factory<_i456.GetPostDetailUsecase>(
      () => registerModule.getPostDetailUsecase,
    );
    gh.factory<_i456.GetCommentsUsecase>(
      () => registerModule.getCommentsUsecase,
    );
    gh.factory<_i456.ToggleLikeUsecase>(() => registerModule.toggleLikeUsecase);
    gh.factory<_i456.CreateCommentUsecase>(
      () => registerModule.createCommentUsecase,
    );
    gh.factory<_i456.UpdateCommentUsecase>(
      () => registerModule.updateCommentUsecase,
    );
    gh.factory<_i456.DeleteCommentUsecase>(
      () => registerModule.deleteCommentUsecase,
    );
    gh.factory<_i456.DeletePostUsecase>(() => registerModule.deletePostUsecase);
    gh.factory<_i456.DeletePostFolderUsecase>(
      () => registerModule.deletePostFolderUsecase,
    );
    gh.factory<_i456.UpdatePostUsecase>(() => registerModule.updatePostUsecase);
    gh.factory<_i456.GetMyPostUsecase>(() => registerModule.getMyPostUsecase);
    gh.factory<_i293.PostListBloc>(
      () => _i293.PostListBloc(
        getPostsUsecase: gh<_i456.GetPostsUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
        toggleLikeUsecase: gh<_i456.ToggleLikeUsecase>(),
      ),
    );
    gh.lazySingleton<_i503.ProfileRepository>(
      () => registerModule.profileRepository,
    );
    gh.singleton<_i583.GoRouter>(
      () => registerModule.router(gh<_i226.AuthenticationBloc>()),
    );
    gh.factory<_i208.LoginBloc>(
      () => _i208.LoginBloc(loginUsecase: gh<_i378.LoginUsecase>()),
    );
    gh.factory<_i150.MyPostListBloc>(
      () => _i150.MyPostListBloc(
        getMyPostUsecase: gh<_i456.GetMyPostUsecase>(),
        toggleLikeUsecase: gh<_i456.ToggleLikeUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
      ),
    );
    gh.factory<_i686.PostFormBloc>(
      () => _i686.PostFormBloc(
        createPostUseCase: gh<_i456.CreatePostUsecase>(),
        uploadPostImageUseCase: gh<_i456.UploadPostImageUsecase>(),
        updatePostUseCase: gh<_i456.UpdatePostUsecase>(),
        getPostDetailUseCase: gh<_i456.GetPostDetailUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
      ),
    );
    gh.factory<_i557.PostDetailBloc>(
      () => _i557.PostDetailBloc(
        getPostDetailUsecase: gh<_i456.GetPostDetailUsecase>(),
        toggleLikeUsecase: gh<_i456.ToggleLikeUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
        deletePostUsecase: gh<_i456.DeletePostUsecase>(),
        deletePostFolderUsecase: gh<_i456.DeletePostFolderUsecase>(),
      ),
    );
    gh.factory<_i93.SearchPostUsecase>(() => registerModule.searchPostUsecase);
    gh.factory<_i93.SearchUsersUsecase>(
      () => registerModule.searchUsersUsecase,
    );
    gh.factory<_i270.CommentsListBloc>(
      () => _i270.CommentsListBloc(
        getCommentsUsecase: gh<_i456.GetCommentsUsecase>(),
        createCommentUsecase: gh<_i456.CreateCommentUsecase>(),
        deleteCommentUsecase: gh<_i456.DeleteCommentUsecase>(),
        updateCommentUsecase: gh<_i456.UpdateCommentUsecase>(),
        getPostDetailUsecase: gh<_i456.GetPostDetailUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
      ),
    );
    gh.factory<_i503.GetProfileUsecase>(() => registerModule.getProfileUsecase);
    gh.factory<_i503.UpdateProfileUsecase>(
      () => registerModule.updateProfileUsecase,
    );
    gh.factory<_i608.SearchBloc>(
      () => _i608.SearchBloc(
        searchUsersUsecase: gh<_i93.SearchUsersUsecase>(),
        searchPostUsecase: gh<_i93.SearchPostUsecase>(),
        toggleLikeUsecase: gh<_i456.ToggleLikeUsecase>(),
        globalEventBus: gh<_i91.GlobalEventBus>(),
      ),
    );
    gh.factory<_i634.UserProfileBloc>(
      () => _i634.UserProfileBloc(
        getProfileUsecase: gh<_i503.GetProfileUsecase>(),
      ),
    );
    gh.factory<_i349.ProfileBloc>(
      () => _i349.ProfileBloc(
        getProfileUsecase: gh<_i503.GetProfileUsecase>(),
        authenticationBloc: gh<_i226.AuthenticationBloc>(),
      ),
    );
    gh.factory<_i1033.EditProfileBloc>(
      () => _i1033.EditProfileBloc(
        updateProfileUsecase: gh<_i503.UpdateProfileUsecase>(),
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
  _i66.SupabaseSearchRemoteDataSource get searchRemoteDataSource =>
      _i66.SupabaseSearchRemoteDataSource(
        supabaseClient: _getIt<_i454.SupabaseClient>(),
      );

  @override
  _i661.SupabaseProfileRemoteDataSource get profileRemoteDataSource =>
      _i661.SupabaseProfileRemoteDataSource(
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
  _i66.SearchRepositoryImpl get searchRepository => _i66.SearchRepositoryImpl(
    searchRemoteDataSource: _getIt<_i66.SearchRemoteDataSource>(),
  );

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

  @override
  _i456.GetPostDetailUsecase get getPostDetailUsecase =>
      _i456.GetPostDetailUsecase(
        postRepository: _getIt<_i456.PostRepository>(),
      );

  @override
  _i456.GetCommentsUsecase get getCommentsUsecase =>
      _i456.GetCommentsUsecase(postRepository: _getIt<_i456.PostRepository>());

  @override
  _i456.ToggleLikeUsecase get toggleLikeUsecase =>
      _i456.ToggleLikeUsecase(postRepository: _getIt<_i456.PostRepository>());

  @override
  _i456.CreateCommentUsecase get createCommentUsecase =>
      _i456.CreateCommentUsecase(
        postRepository: _getIt<_i456.PostRepository>(),
      );

  @override
  _i456.UpdateCommentUsecase get updateCommentUsecase =>
      _i456.UpdateCommentUsecase(
        postRepository: _getIt<_i456.PostRepository>(),
      );

  @override
  _i456.DeleteCommentUsecase get deleteCommentUsecase =>
      _i456.DeleteCommentUsecase(
        postRepository: _getIt<_i456.PostRepository>(),
      );

  @override
  _i456.DeletePostUsecase get deletePostUsecase =>
      _i456.DeletePostUsecase(postRepository: _getIt<_i456.PostRepository>());

  @override
  _i456.DeletePostFolderUsecase get deletePostFolderUsecase =>
      _i456.DeletePostFolderUsecase(
        postRepository: _getIt<_i456.PostRepository>(),
      );

  @override
  _i456.UpdatePostUsecase get updatePostUsecase =>
      _i456.UpdatePostUsecase(postRepository: _getIt<_i456.PostRepository>());

  @override
  _i456.GetMyPostUsecase get getMyPostUsecase =>
      _i456.GetMyPostUsecase(postRepository: _getIt<_i456.PostRepository>());

  @override
  _i661.ProfileRepositoryImpl get profileRepository =>
      _i661.ProfileRepositoryImpl(
        profileRemoteDataSource: _getIt<_i661.ProfileRemoteDataSource>(),
      );

  @override
  _i93.SearchPostUsecase get searchPostUsecase =>
      _i93.SearchPostUsecase(searchRepository: _getIt<_i93.SearchRepository>());

  @override
  _i93.SearchUsersUsecase get searchUsersUsecase => _i93.SearchUsersUsecase(
    searchRepository: _getIt<_i93.SearchRepository>(),
  );

  @override
  _i503.GetProfileUsecase get getProfileUsecase => _i503.GetProfileUsecase(
    profileRepository: _getIt<_i503.ProfileRepository>(),
  );

  @override
  _i503.UpdateProfileUsecase get updateProfileUsecase =>
      _i503.UpdateProfileUsecase(
        profileRepository: _getIt<_i503.ProfileRepository>(),
      );
}
