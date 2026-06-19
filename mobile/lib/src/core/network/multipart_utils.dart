import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

Future<MultipartFile> multipartFileFromXFile(
  XFile file, {
  String? filename,
}) async {
  final bytes = await file.readAsBytes();
  final resolvedName = filename ?? _resolveFilename(file);

  return MultipartFile.fromBytes(
    bytes,
    filename: resolvedName,
  );
}

String _resolveFilename(XFile file) {
  final name = file.name.trim();
  if (name.isNotEmpty && name.contains('.')) {
    return name;
  }

  final pathSegment = file.path.split('/').last.split('\\').last;
  if (pathSegment.contains('.') && !pathSegment.startsWith('blob:')) {
    return pathSegment;
  }

  return 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
}
