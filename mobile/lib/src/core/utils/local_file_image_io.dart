import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalFileImageImpl(String path, {BoxFit fit = BoxFit.contain}) {
  return Image.file(File(path), fit: fit);
}
