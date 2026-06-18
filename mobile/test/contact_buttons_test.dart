import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/core/auth/app_permissions.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/core/utils/contact_launcher.dart';

void main() {
  test('buyer role can contact other sellers cars', () {
    expect(
      AppPermissions.canContactAboutCar(AppRoles.buyer, isOwnCar: false),
      isTrue,
    );
  });

  test('seller cannot contact own car', () {
    expect(
      AppPermissions.canContactAboutCar(AppRoles.seller, isOwnCar: true),
      isFalse,
    );
  });

  test('seller can contact other showrooms cars', () {
    expect(
      AppPermissions.canContactAboutCar(AppRoles.seller, isOwnCar: false),
      isTrue,
    );
  });

  test('whatsapp link converts Iraqi local number to international', () {
    expect(ContactLauncher.whatsappDigits('0772-000-0010'), '9647720000010');
    expect(
      ContactLauncher.whatsappUri('07720000010').toString(),
      'https://wa.me/9647720000010',
    );
  });

  test('phone validation requires at least 7 digits', () {
    expect(ContactLauncher.isValidPhone('07720000010'), isTrue);
    expect(ContactLauncher.isValidPhone(''), isFalse);
    expect(ContactLauncher.isValidPhone('123'), isFalse);
  });

  test('whatsapp tries multiple uri formats', () {
    final uris = ContactLauncher.whatsappUri('07720000010').toString();
    expect(uris, 'https://wa.me/9647720000010');
  });

  test('whatsapp link keeps numbers already in 964 format', () {
    expect(ContactLauncher.whatsappDigits('9647720000010'), '9647720000010');
    expect(ContactLauncher.whatsappDigits('+9647720000010'), '9647720000010');
  });

  test('phone link uses showroom phone', () {
    const phone = '07720000010';
    final tel = ContactLauncher.phoneUri(phone).toString();
    expect(tel, 'tel:07720000010');
  });
}
