part of 'edit_profile_bloc.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

final class EditProfileSubmitted extends EditProfileEvent {
  const EditProfileSubmitted({
    required this.userId,
    this.originalAvatarUrl,
    required this.username,
    this.newAvatarUrl,
    this.avatarWasRemoved = false,
  });

  final String userId;
  final String? originalAvatarUrl;
  final String username;
  final File? newAvatarUrl;
  final bool avatarWasRemoved;

  @override
  List<Object?> get props => [
    userId,
    originalAvatarUrl,
    username,
    newAvatarUrl,
    avatarWasRemoved,
  ];
}
