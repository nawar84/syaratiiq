import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens phone / WhatsApp links on device (Android 11+ package visibility safe).
class ContactLauncher {
  /// Iraqi local `07…` → `9647…` for [wa.me](https://wa.me).
  static String whatsappDigits(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = '964${digits.substring(1)}';
    } else if (!digits.startsWith('964')) {
      digits = '964$digits';
    }
    return digits;
  }

  static bool isValidPhone(String phone) => phone.replaceAll(RegExp(r'\D'), '').length >= 7;

  static Uri whatsappUri(String phone) {
    return Uri.parse('https://wa.me/${whatsappDigits(phone)}');
  }

  static Uri phoneUri(String phone) {
    return Uri.parse('tel:${phone.replaceAll(RegExp(r'\s'), '')}');
  }

  static List<Uri> _whatsappUris(String phone) {
    final digits = whatsappDigits(phone);
    final uris = <Uri>[
      Uri.parse('https://wa.me/$digits'),
      Uri.parse('https://api.whatsapp.com/send?phone=$digits'),
    ];
    if (Platform.isAndroid || Platform.isIOS) {
      uris.insert(0, Uri.parse('whatsapp://send?phone=$digits'));
    }
    return uris;
  }

  static Future<bool> openWhatsApp(String phone) async {
    if (!isValidPhone(phone)) return false;

    for (final uri in _whatsappUris(phone)) {
      if (await _open(uri)) return true;
    }
    return false;
  }

  static Future<bool> openPhone(String phone) async {
    if (!isValidPhone(phone)) return false;
    return _open(phoneUri(phone));
  }

  static Future<void> openWhatsAppOrNotify(BuildContext context, String phone) async {
    if (!isValidPhone(phone)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير متوفر لهذا المعرض.')),
      );
      return;
    }

    final opened = await openWhatsApp(phone);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر فتح واتساب. تأكد من تثبيت التطبيق.')),
    );
  }

  static Future<void> openPhoneOrNotify(BuildContext context, String phone) async {
    if (!isValidPhone(phone)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير متوفر لهذا المعرض.')),
      );
      return;
    }

    final opened = await openPhone(phone);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر فتح تطبيق الاتصال.')),
    );
  }

  static Future<bool> _open(Uri uri) async {
    const modes = [
      LaunchMode.externalNonBrowserApplication,
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    ];

    for (final mode in modes) {
      try {
        if (await launchUrl(uri, mode: mode)) return true;
      } catch (_) {
        // Try the next launch mode / URI.
      }
    }
    return false;
  }
}
