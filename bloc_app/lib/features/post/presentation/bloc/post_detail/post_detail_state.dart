part of 'post_detail_bloc.dart';

enum PostDetailStatus { initial, loading, loaded, failure, submitting }

class PostDetailState extends Equatable {
  const PostDetailState({
    this.status = PostDetailStatus.initial,
    this.post,
    this.failure,
    this.transientFailure,
    this.deletionSuccess = false,
    this.isAcknowledging = false,
    this.isLiking = false,
  });

  final PostDetailStatus status;
  final PostDisplay? post;
  final Failures? failure;
  final Failures? transientFailure;
  final bool deletionSuccess;
  final bool isAcknowledging;
  final bool isLiking;

  @override
  List<Object?> get props => [
    status,
    post,
    failure,
    transientFailure,
    deletionSuccess,
    isAcknowledging,
    isLiking,
  ];

  PostDetailState copyWith({
    PostDetailStatus? status,
    PostDisplay? Function()? post,
    Failures? Function()? failure,
    Failures? Function()? transientFailure,
    bool? deletionSuccess,
    bool? isAcknowledging,
    bool? isLiking,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      post: post != null ? post() : this.post,
      failure: failure != null ? failure() : this.failure,
      transientFailure: transientFailure != null
          ? transientFailure()
          : this.transientFailure,
      deletionSuccess: deletionSuccess ?? this.deletionSuccess,
      isAcknowledging: isAcknowledging ?? this.isAcknowledging,
      isLiking: isLiking ?? this.isLiking,
    );
  }
}
