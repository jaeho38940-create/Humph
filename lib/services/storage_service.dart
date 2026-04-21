import 'dart:io';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

class StorageService {
  static const _bucket = 'post-images';
  final _uuid = const Uuid();

  Future<String> uploadImage(File file, String userId) async {
    final ext = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$ext';
    final path = '$userId/$fileName';

    await supabase.storage.from(_bucket).upload(path, file);
    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  Future<List<String>> uploadImages(List<File> files, String userId) async {
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
}
