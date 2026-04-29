import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

class StorageService {
  static const _bucket = 'post-images';

  /// Max dimension (width or height) in pixels. Larger images are downscaled.
  static const _maxDimension = 1280;

  /// JPEG quality 0–100. 82 is roughly equivalent to Instagram's compression.
  static const _jpegQuality = 82;

  final _uuid = const Uuid();

  Future<String> uploadImage(XFile file, String userId) async {
    final fileName = '${_uuid.v4()}.jpg';
    final path = '$userId/$fileName';

    final compressed = await _compress(file);

    await supabase.storage.from(_bucket).uploadBinary(
      path,
      compressed,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: false,
      ),
    );
    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  Future<List<String>> uploadImages(List<XFile> files, String userId) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadImage(file, userId);
      urls.add(url);
    }
    return urls;
  }

  Future<void> deleteImage(String imageUrl) async {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    final bucketIndex = pathSegments.indexOf(_bucket);
    if (bucketIndex < 0) return;

    final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
    await supabase.storage.from(_bucket).remove([storagePath]);
  }

  Future<Uint8List> _compress(XFile file) async {
    final bytes = await file.readAsBytes();

    // Decode to image object (pure Dart — works on web + mobile)
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes; // fallback: upload as-is

    // Downscale only if larger than max dimension
    final img.Image resized;
    if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? _maxDimension : -1,
        height: decoded.height > decoded.width ? _maxDimension : -1,
        interpolation: img.Interpolation.linear,
      );
    } else {
      resized = decoded;
    }

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: _jpegQuality),
    );
  }
}
