import 'package:flutter/material.dart';

Widget buildLocalFileImageImpl(String path, {BoxFit fit = BoxFit.contain}) {
  return Image.network(path, fit: fit);
}
