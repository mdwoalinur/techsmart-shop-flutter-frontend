class CustomerProfile {
  const CustomerProfile({
    required this.customerId,
    required this.customerCode,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.customerType,
    required this.emailVerified,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.photoUrl,
  });
  final int customerId;
  final String customerCode;
  final String fullName;
  final String email;
  final String phone;
  final String customerType;
  final bool emailVerified;
  final String? address, city, state, postalCode, country, photoUrl;
  CustomerProfile copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? photoUrl,
  }) => CustomerProfile(
    customerId: customerId,
    customerCode: customerCode,
    fullName: fullName ?? this.fullName,
    email: email,
    phone: phone ?? this.phone,
    customerType: customerType,
    emailVerified: emailVerified,
    address: address ?? this.address,
    city: city ?? this.city,
    state: state ?? this.state,
    postalCode: postalCode ?? this.postalCode,
    country: country ?? this.country,
    photoUrl: photoUrl ?? this.photoUrl,
  );
  factory CustomerProfile.fromJson(Map<String, Object?> j) => CustomerProfile(
    customerId: _int(j, 'customerId'),
    customerCode: _string(j, 'customerCode'),
    fullName: _string(j, 'fullName'),
    email: _string(j, 'email'),
    phone: _string(j, 'phone'),
    customerType: _string(j, 'customerType'),
    emailVerified: j['emailVerified'] == true,
    address: j['address'] as String?,
    city: j['city'] as String?,
    state: j['state'] as String?,
    postalCode: j['postalCode'] as String?,
    country: j['country'] as String?,
    photoUrl: j['photoUrl'] as String?,
  );
  static String _string(Map<String, Object?> j, String k) {
    final v = j[k];
    if (v is! String) throw FormatException('Missing $k');
    return v;
  }

  static int _int(Map<String, Object?> j, String k) {
    final v = j[k];
    if (v is! num) throw FormatException('Missing $k');
    return v.toInt();
  }
}
