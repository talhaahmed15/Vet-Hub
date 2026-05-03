class PackagePlan {
  final String packageId;
  final String packageKey;
  final String name;
  final int trialDays;
  final int priceCents;
  final String billingCycle;
  final bool isActive;

  const PackagePlan({
    required this.packageId,
    required this.packageKey,
    required this.name,
    required this.trialDays,
    required this.priceCents,
    required this.billingCycle,
    required this.isActive,
  });

  factory PackagePlan.fromMap(Map<String, dynamic> map) {
    return PackagePlan(
      packageId: map['package_id']?.toString() ?? '',
      packageKey: map['package_key']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      trialDays: _parseInt(map['trial_days']),
      priceCents: _parseInt(map['price_cents']),
      billingCycle: map['billing_cycle']?.toString() ?? 'monthly',
      isActive: map['is_active'] == true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
