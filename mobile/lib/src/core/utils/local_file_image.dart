import 'package:flutter/material.dart';

import 'local_file_image_stub.dart'
    if (dart.library.io) 'local_file_image_io.dart';

Widget buildLocalFileImage(String path, {BoxFit fit = BoxFit.contain}) {
  return buildLocalFileImageImpl(path, fit: fit);
}
