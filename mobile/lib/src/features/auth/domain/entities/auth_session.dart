class AuthSession {
  const AuthSession({
    required this.token,
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.username,
    this.accountStatus,
    this.canManageCars = true,
    this.subscriptionEnd,
    this.showroomName,
  });

  final String token;
  final int id;
  final String name;
  final String phone;
  final String role;
  final String? username;
  final String? accountStatus;
  final bool canManageCars;
  final String? subscriptionEnd;
  final String? showroomName;

  bool get isExpired => accountStatus == 'expired';
  bool get isSuspended => accountStatus == 'suspended';

  Map<String, dynamic> toJson() => {
        'token': token,
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'username': username,
        'account_status': accountStatus,
        'can_manage_cars': canManageCars,
        'subscription_end': subscriptionEnd,
        'showroom_name': showroomName,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      username: json['username'] as String?,
      accountStatus: json['account_status'] as String?,
      canManageCars: json['can_manage_cars'] as bool? ?? true,
      subscriptionEnd: json['subscription_end'] as String?,
      showroomName: json['showroom_name'] as String?,
    );
  }
}
