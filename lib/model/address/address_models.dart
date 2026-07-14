class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    this.area,
    required this.city,
    required this.district,
    required this.division,
    this.postalCode,
    required this.country,
    this.instructions,
    required this.isDefault,
    required this.active,
  });
  final int id;
  final String label,
      recipientName,
      phone,
      addressLine1,
      city,
      district,
      division,
      country;
  final String? addressLine2, area, postalCode, instructions;
  final bool isDefault, active;
  factory CustomerAddress.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return CustomerAddress(
      id: (j['id'] as num).toInt(),
      label: j['label'] as String,
      recipientName: j['recipientName'] as String,
      phone: j['phone'] as String,
      addressLine1: j['addressLine1'] as String,
      addressLine2: j['addressLine2'] as String?,
      area: j['area'] as String?,
      city: j['city'] as String,
      district: j['district'] as String,
      division: j['division'] as String,
      postalCode: j['postalCode'] as String?,
      country: j['country'] as String,
      instructions: j['deliveryInstructions'] as String?,
      isDefault: j['defaultAddress'] == true,
      active: j['active'] == true,
    );
  }
  String get summary => '$addressLine1, $city, $district, $division';
}

class AddressDraft {
  AddressDraft({
    this.label = 'Home',
    this.recipientName = '',
    this.phone = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.area = '',
    this.city = '',
    this.district = '',
    this.division = '',
    this.postalCode = '',
    this.country = 'Bangladesh',
    this.instructions = '',
    this.isDefault = false,
  });
  String label,
      recipientName,
      phone,
      addressLine1,
      addressLine2,
      area,
      city,
      district,
      division,
      postalCode,
      country,
      instructions;
  bool isDefault;
  Map<String, Object?> toJson() => {
    'label': label,
    'recipientName': recipientName,
    'phone': phone,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'area': area,
    'city': city,
    'district': district,
    'division': division,
    'postalCode': postalCode,
    'country': country,
    'deliveryInstructions': instructions,
    'defaultAddress': isDefault,
  };
}
