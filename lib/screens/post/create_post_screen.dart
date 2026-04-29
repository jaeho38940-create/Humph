import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/post_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<XFile> _selectedImages = [];
  String _selectedCategory = 'Electronics';
  String _currency = 'USD';
  bool _isFree = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= AppConstants.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 images allowed')),
      );
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      final remaining = AppConstants.maxImages - _selectedImages.length;
      final toAdd = images.take(remaining).toList();
      setState(() => _selectedImages.addAll(toAdd));
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= AppConstants.maxImages) return;

    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() => _selectedImages.add(photo));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    final priceText = _priceController.text.replaceAll(',', '').trim();
    final priceValue = double.tryParse(priceText) ?? 0;
    // USD is stored in cents (smallest unit). KRW has no fractional unit.
    final storedPrice = _isFree
        ? 0
        : (_currency == 'KRW' ? priceValue.round() : (priceValue * 100).round());

    final post = await ref.read(createPostProvider.notifier).createPost(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: storedPrice,
      isFree: _isFree,
      category: _selectedCategory,
      userId: userId,
      currency: _currency,
      images: _selectedImages,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (post != null) {
        ref.read(postsProvider.notifier).refresh();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPostProvider);

    return Scaffold(
      backgroundColor: HumphTheme.background,
      appBar: AppBar(
        title: const Text('Post for Sale'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: Text(
              'Done',
              style: TextStyle(
                color: _isSubmitting ? HumphTheme.onSurfaceVariant : HumphTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Image picker section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: HumphTheme.divider, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Camera / Gallery button
                        GestureDetector(
                          onTap: () => _showImageSourceSheet(),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: HumphTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: HumphTheme.divider),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined,
                                    color: HumphTheme.onSurfaceVariant, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedImages.length}/${AppConstants.maxImages}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: HumphTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Selected images
                        ..._selectedImages.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb
                                      ? Image.network(
                                          entry.value.path,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(entry.value.path),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                if (entry.key == 0)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cover',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(entry.key),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(color: HumphTheme.onBackground, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  filled: false,
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
            ),
            const Divider(height: 1),
            // Category selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.categories.length - 1, // Skip 'All'
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = AppConstants.categories[index + 1];
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: Chip(
                        label: Text(category),
                        backgroundColor: isSelected
                            ? HumphTheme.onBackground
                            : HumphTheme.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? HumphTheme.background
                              : HumphTheme.onSurface,
                          fontSize: 13,
                        ),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            // Description
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: HumphTheme.onBackground, fontSize: 15),
                maxLines: 8,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe your item. Include condition, brand, size, etc.',
                  filled: false,
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(height: 1),
            // Price section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HumphTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sell / Free toggle
                  Row(
                    children: [
                      _buildToggleButton('Sell', !_isFree, () {
                        setState(() => _isFree = false);
                      }),
                      const SizedBox(width: 8),
                      _buildToggleButton('Free', _isFree, () {
                        setState(() {
                          _isFree = true;
                          _priceController.clear();
                        });
                      }),
                    ],
                  ),
                  if (!_isFree) ...[
                    const SizedBox(height: 16),
                    // Currency toggle (USD / KRW)
                    Row(
                      children: [
                        const Text(
                          'Currency',
                          style: TextStyle(
                            fontSize: 14,
                            color: HumphTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildCurrencyChip('USD', '\$'),
                        const SizedBox(width: 8),
                        _buildCurrencyChip('KRW', '₩'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      style: const TextStyle(
                          color: HumphTheme.onBackground, fontSize: 16),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: _currency == 'USD',
                      ),
                      decoration: InputDecoration(
                        prefixText: '${_currency == 'KRW' ? '₩' : '\$'} ',
                        prefixStyle: const TextStyle(
                          color: HumphTheme.onBackground,
                          fontSize: 16,
                        ),
                        hintText: _currency == 'KRW'
                            ? 'Enter price in won'
                            : 'Enter price in dollars',
                        filled: true,
                        fillColor: HumphTheme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (_isFree) return null;
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        final cleaned = value.replaceAll(',', '').trim();
                        final parsed = double.tryParse(cleaned);
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            // Location
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meetup Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HumphTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: HumphTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: HumphTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Camp Humphreys',
                          style: TextStyle(
                            fontSize: 15,
                            color: HumphTheme.onBackground,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.close,
                            size: 18, color: HumphTheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Loading indicator
            if (_isSubmitting || createState.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: HumphTheme.primary),
                ),
              ),
            // Submit button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HumphTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: HumphTheme.surfaceVariant,
                  ),
                  child: Text(
                    _isSubmitting ? 'Posting...' : 'Post',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyChip(String code, String symbol) {
    final isActive = _currency == code;
    return GestureDetector(
      onTap: () {
        if (_currency != code) {
          setState(() {
            _currency = code;
            _priceController.clear();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? HumphTheme.primary : HumphTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$symbol $code',
          style: TextStyle(
            color: isActive ? Colors.white : HumphTheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? HumphTheme.onBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? HumphTheme.onBackground : HumphTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? HumphTheme.background : HumphTheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: HumphTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: HumphTheme.onBackground),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: HumphTheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: HumphTheme.onBackground),
              title: const Text('Take a Photo',
                  style: TextStyle(color: HumphTheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
