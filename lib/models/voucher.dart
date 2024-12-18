class Voucher {
  final String id;
  final String category;
  final int discountPercentage;
  final DateTime expiryDate;
  final String terms;
  final int minPurchase;
  final int maxDiscount;
  DateTime? usedDate;
  bool isUsed;

  Voucher({
    required this.id,
    required this.category,
    required this.discountPercentage,
    required this.expiryDate,
    required this.terms,
    required this.minPurchase,
    required this.maxDiscount,
    this.usedDate,
    this.isUsed = false,
  }) : assert(minPurchase <= maxDiscount, 'Minimum purchase should not exceed maximum discount');

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  
  String get formattedValidUntil {
    return "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
  }

  String get formattedUsedDate {
    return usedDate != null 
        ? "${usedDate!.day}/${usedDate!.month}/${usedDate!.year}"
        : "Not used yet";
  }

  void markAsUsed() {
    isUsed = true;
    usedDate = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'discountPercentage': discountPercentage,
    'expiryDate': expiryDate.toIso8601String(),
    'terms': terms,
    'minPurchase': minPurchase,
    'maxDiscount': maxDiscount,
    'usedDate': usedDate?.toIso8601String(),
    'isUsed': isUsed,
    'isExpired': isExpired,
  };

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id'],
    category: json['category'],
    discountPercentage: json['discountPercentage'],
    expiryDate: DateTime.parse(json['expiryDate']),
    terms: json['terms'],
    minPurchase: json['minPurchase'],
    maxDiscount: json['maxDiscount'],
    usedDate: json['usedDate'] != null ? DateTime.parse(json['usedDate']) : null,
    isUsed: json['isUsed'] ?? false,
  );
}
