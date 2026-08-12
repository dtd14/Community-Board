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
  });

  final String title;
  final String content;
  final File? imageFile;
  @override
  List<Object?> get props => [title, content, imageFile];
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
  });

  final PostDisplay originalPost;
  final String newTitle;
  final String newContent;
  final File? newImage;
  final bool imageWasRemoved;

  @override
  List<Object?> get props => [
    originalPost,
    newTitle,
    newContent,
    newImage,
    imageWasRemoved,
  ];
}
