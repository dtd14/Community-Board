import 'package:domain/media.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/utils.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/post_badges.dart';
import '../bloc/post_form/post_form_bloc.dart';

import 'package:image_picker/image_picker.dart';

class PostFormPage extends StatelessWidget {
  const PostFormPage({super.key, this.postId});
  final String? postId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<PostFormBloc>();
        if (postId != null) {
          bloc.add(PostFormPrefilled(postId: postId!));
        }
        return bloc;
      },
      child: PostFormView(isEditMode: postId != null, postId: postId),
    );
  }
}

class PostFormView extends StatefulWidget {
  const PostFormView({super.key, required this.isEditMode, this.postId});
  final bool isEditMode;
  final String? postId;

  @override
  State<PostFormView> createState() => _PostFormViewState();
}

class _PostFormViewState extends State<PostFormView> {
  final _formkey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  UploadImage? _selectedImage;

  String? _existingImageUrl;
  bool _imageWasRemoved = false;
  PostDisplay? _originalPost;

  bool _isSaving = false;
  String _category = PostCategories.announcement;
  bool _isPinned = false;
  bool _requiresAcknowledgement = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImage = UploadImage(bytes: bytes, name: pickedFile.name);
          _imageWasRemoved = false;
        });
      }
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    } catch (e) {
      print('Unexpected error occurred: $e');
      if (!mounted) return;
      showErrorSnackbar(context, message: e.toString());
    }
  }

  void _submit(PostDisplay? postToEdit) {
    if (_isSaving) return;
    if (widget.isEditMode && postToEdit == null) return;
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    final form = _formkey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (postToEdit != null) {
      context.read<PostFormBloc>().add(
        PostEdited(
          originalPost: postToEdit,
          newTitle: title,
          newContent: content,
          newImage: _selectedImage,
          imageWasRemoved: _imageWasRemoved,
          category: _category,
          isPinned: _isPinned,
          requiresAcknowledgement: _requiresAcknowledgement,
        ),
      );
    } else {
      context.read<PostFormBloc>().add(
        PostSubmitted(
          title: title,
          content: content,
          imageFile: _selectedImage,
          category: _category,
          isPinned: _isPinned,
          requiresAcknowledgement: _requiresAcknowledgement,
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    Widget? imageWidget;

    if (_selectedImage != null) {
      imageWidget = Image.memory(
        _selectedImage!.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (_existingImageUrl != null && !_imageWasRemoved) {
      imageWidget = CachedNetworkImage(
        imageUrl: _existingImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Center(child: Icon(Icons.error)),
      );
    }

    if (imageWidget != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _imageWasRemoved = true;
                });
              },
              icon: const Icon(Icons.cancel, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text('Chạm để thêm ảnh minh họa'),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostFormBloc, PostFormState>(
      listener: (context, state) {
        if (state is PostFormLoadFailure) {
          showErrorSnackbar(context, message: state.failure.message);
          setState(() {
            _isSaving = false;
          });
        }
        if (state is PostFormLoadSuccess) {
          if (widget.isEditMode && _originalPost == null) {
            _originalPost = state.data;
            _titleController.text = _originalPost!.title;
            _contentController.text = _originalPost!.content;
            _existingImageUrl = _originalPost!.imageUrl;
            _category = _originalPost!.category;
            _isPinned = _originalPost!.isPinned;
            _requiresAcknowledgement = _originalPost!.requiresAcknowledgement;
          } else {
            context.pop();
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is PostFormLoadInProgress;
        final isEditMode = widget.isEditMode;
        if (isEditMode &&
            _originalPost == null &&
            state is PostFormLoadFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chỉnh sửa bài viết')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.failure.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    if (widget.postId != null)
                      FilledButton(
                        onPressed: () => context.read<PostFormBloc>().add(
                          PostFormPrefilled(postId: widget.postId!),
                        ),
                        child: const Text('Thử lại'),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(isEditMode ? 'Chỉnh sửa bài viết' : 'Tạo bài viết'),
          ),
          body: _isSaving || (isLoading && _originalPost == null)
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formkey,
                        autovalidateMode: _autovalidateMode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Chia sẻ thông tin với đồng nghiệp',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nội dung rõ ràng giúp mọi người cập nhật và phối hợp tốt hơn.',
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Loại bài viết',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: PostCategories.values
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(postCategoryLabel(category)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 200,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade100,
                              ),
                              child: InkWell(
                                onTap: isLoading ? null : _pickImage,
                                child: _buildImagePreview(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Tiêu đề',
                                hintText: 'Thông tin chính bạn muốn truyền tải',
                              ),
                              enabled: !isLoading,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tiêu đề.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _contentController,
                              decoration: const InputDecoration(
                                labelText: 'Nội dung',
                                alignLabelWithHint: true,
                              ),
                              maxLines: 10,
                              minLines: 5,
                              enabled: !isLoading,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập nội dung.';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 24),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('Ghim bài viết'),
                                    subtitle: const Text(
                                      'Ưu tiên hiển thị ở đầu bảng tin.',
                                    ),
                                    secondary: const Icon(
                                      Icons.push_pin_outlined,
                                      color: AppColors.primary,
                                    ),
                                    value: _isPinned,
                                    onChanged: (value) =>
                                        setState(() => _isPinned = value),
                                  ),
                                  const Divider(height: 1),
                                  SwitchListTile(
                                    title: const Text(
                                      'Yêu cầu xác nhận đã đọc',
                                    ),
                                    subtitle: const Text(
                                      'Dành cho thông báo hoặc quy định cần theo dõi tiếp nhận.',
                                    ),
                                    secondary: const Icon(
                                      Icons.fact_check_outlined,
                                      color: AppColors.primary,
                                    ),
                                    value: _requiresAcknowledgement,
                                    onChanged: (value) => setState(
                                      () => _requiresAcknowledgement = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_originalPost?.requiresAcknowledgement == true)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'Thay đổi tiêu đề hoặc nội dung sẽ yêu cầu nhân viên xác nhận lại.',
                                  style: TextStyle(color: AppColors.mutedText),
                                ),
                              ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: () => _submit(_originalPost),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                isEditMode ? 'Lưu thay đổi' : 'Đăng bài viết',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
