class SecurityModel {
  const SecurityModel({
    required this.recordId,
    required this.is2faEnabled,
    required this.twoFactorType,
    required this.failedAttempts,
    required this.lockedUntil,
    required this.userEmail,
    required this.isExternalProvider,
    required this.providerLabel,
    required this.lastSignInAt,
    this.verifiedTotpFactorId,
  });

  final String recordId;
  final bool is2faEnabled;
  final String? twoFactorType; // 'EMAIL' | 'APP' | null
  final int failedAttempts;
  final DateTime? lockedUntil;
  final String userEmail;
  final bool isExternalProvider;
  final String providerLabel;
  final DateTime? lastSignInAt;
  final String? verifiedTotpFactorId;

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  String get twoFactorLabel {
    switch (twoFactorType?.toUpperCase()) {
      case 'EMAIL':
        return 'Correo electrónico';
      case 'APP':
        return 'Aplicación autenticadora';
      default:
        return 'No configurado';
    }
  }

  SecurityModel copyWith({
    bool? is2faEnabled,
    String? twoFactorType,
    bool clearTwoFactorType = false,
    String? verifiedTotpFactorId,
    bool clearTotpFactorId = false,
  }) {
    return SecurityModel(
      recordId: recordId,
      is2faEnabled: is2faEnabled ?? this.is2faEnabled,
      twoFactorType: clearTwoFactorType
          ? null
          : (twoFactorType ?? this.twoFactorType),
      failedAttempts: failedAttempts,
      lockedUntil: lockedUntil,
      userEmail: userEmail,
      isExternalProvider: isExternalProvider,
      providerLabel: providerLabel,
      lastSignInAt: lastSignInAt,
      verifiedTotpFactorId: clearTotpFactorId
          ? null
          : (verifiedTotpFactorId ?? this.verifiedTotpFactorId),
    );
  }
}
