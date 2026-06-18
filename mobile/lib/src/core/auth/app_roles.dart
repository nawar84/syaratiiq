/// Platform roles: admin, seller (owner in API), buyer.
class AppRoles {
  AppRoles._();

  static const admin = 'admin';
  static const seller = 'owner';
  static const buyer = 'buyer';

  static bool isAdmin(String role) => role == admin;

  static bool isSeller(String role) => role == seller;

  static bool isBuyer(String role) => role == buyer || role == 'visitor';

  static String label(String role) => switch (role) {
        admin => 'أدمن',
        seller => 'بائع',
        buyer => 'مشتري',
        'visitor' => 'مشتري',
        _ => role,
      };

  static const assignableRoles = [buyer, seller, admin];
}
