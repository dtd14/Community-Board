class UserEntity {
  const UserEntity({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.role,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String role;
}
