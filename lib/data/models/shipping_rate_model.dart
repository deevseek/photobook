class ShippingRateModel {
  final String service;
  final String serviceName;
  final String estimatedDays;
  final String courier;
  final int cost;

  ShippingRateModel({
    required this.service,
    required this.serviceName,
    required this.cost,
    required this.estimatedDays,
    required this.courier,
  });

  factory ShippingRateModel.fromJson(Map<String, dynamic> json) {
    return ShippingRateModel(
      service: (json['service'] ?? '-').toString(),
      serviceName: (json['service_name'] ?? json['description'] ?? '-').toString(),
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      estimatedDays: (json['estimated_days'] ?? json['etd'] ?? '-').toString(),
      courier: (json['courier'] ?? 'JNT').toString(),
    );
  }
}
