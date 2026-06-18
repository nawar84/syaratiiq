import 'package:mobile/src/core/auth/app_roles.dart';

/// Role-based UI and action permissions for the marketplace.
class AppPermissions {
  AppPermissions._();

  static bool canEditCar(String role, {required bool isOwnCar}) {
    if (AppRoles.isAdmin(role)) return true;
    if (AppRoles.isSeller(role)) return isOwnCar;
    return false;
  }

  static bool canEditShowroom(String role, {required bool isOwnShowroom}) {
    if (AppRoles.isAdmin(role)) return true;
    if (AppRoles.isSeller(role)) return isOwnShowroom;
    return false;
  }

  /// Buyers and admins may contact any listing; sellers only for others' cars.
  static bool canContactAboutCar(String role, {required bool isOwnCar}) {
    if (AppRoles.isBuyer(role)) return true;
    if (AppRoles.isSeller(role)) return !isOwnCar;
    if (AppRoles.isAdmin(role)) return true;
    return false;
  }

  static bool canContactShowroom(String role, {required bool isOwnShowroom}) {
    if (AppRoles.isBuyer(role)) return true;
    if (AppRoles.isSeller(role)) return !isOwnShowroom;
    if (AppRoles.isAdmin(role)) return true;
    return false;
  }

  static bool canViewShowroomVisitors(String role, {required bool isOwnShowroom}) {
    return isOwnShowroom && (AppRoles.isSeller(role) || AppRoles.isAdmin(role));
  }

  static bool canManageOwnCars(String role) => AppRoles.isSeller(role) || AppRoles.isAdmin(role);

  static bool canUseFavorites(String role) => AppRoles.isBuyer(role);

  /// Sellers may register one showroom; duplicate check is by phone only (names may repeat).
  static bool canAddShowroom(String role, int existingShowroomCount) {
    if (AppRoles.isAdmin(role)) return true;
    if (AppRoles.isSeller(role)) return existingShowroomCount == 0;
    return false;
  }

  static bool isPhoneRegistered(List<String> registeredPhones, String phone) {
    final normalized = _normalizePhone(phone);
    return registeredPhones.any((p) => _normalizePhone(p) == normalized);
  }

  static String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  static bool isOwnShowroom(Set<int> myShowroomIds, int showroomId) =>
      myShowroomIds.contains(showroomId);
}
