part of 'post_form_bloc.dart';

sealed class PostFormEvent extends Equatable {
  const PostFormEvent();

  @override
  List<Object?> get props => [];
}

final class PostSubmitted extends PostFormEvent {
  const PostSubmitted({
    required this.title,
    required this.content,
    this.imageFile,
    this.category = PostCategories.announcement,
    this.isPinned = false,
    this.requiresAcknowledgement = false,
  });

  final String title;
  final String content;
  final UploadImage? imageFile;
  final String category;
  final bool isPinned;
  final bool requiresAcknowledgement;
  @override
  List<Object?> get props => [
    title,
    content,
    imageFile,
    category,
    isPinned,
    requiresAcknowledgement,
  ];
}

final class PostFormPrefilled extends PostFormEvent {
  const PostFormPrefilled({required this.postId});

  final String postId;

  @override
  List<Object?> get props => [postId];
}

final class PostEdited extends PostFormEvent {
  const PostEdited({
    required this.originalPost,
    required this.newTitle,
    required this.newContent,
    this.newImage,
    this.imageWasRemoved = false,
    this.category = PostCategories.announcement,
    this.isPinned = false,
    this.requiresAcknowledgement = false,
  });

  final PostDisplay originalPost;
  final String newTitle;
  final String newContent;
  final UploadImage? newImage;
  final bool imageWasRemoved;
  final String category;
  final bool isPinned;
  final bool requiresAcknowledgement;

  @override
  List<Object?> get props => [
    originalPost,
    newTitle,
    newContent,
    newImage,
    imageWasRemoved,
    category,
    isPinned,
    requiresAcknowledgement,
  ];
}
