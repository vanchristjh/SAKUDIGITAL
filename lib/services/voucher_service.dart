import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import '../models/voucher.dart';

class VoucherService {
  static const String _vouchersKey = 'vouchers';
  final SharedPreferences _prefs;

  VoucherService(this._prefs);

  Future<List<Voucher>> getVouchers() async {
    final String? vouchersJson = _prefs.getString(_vouchersKey);
    if (vouchersJson == null) return [];

    final List<dynamic> vouchersList = json.decode(vouchersJson);
    return vouchersList.map((json) => Voucher.fromJson(json)).toList();
  }

  Future<void> saveVouchers(List<Voucher> vouchers) async {
    final String vouchersJson = json.encode(
      vouchers.map((v) => v.toJson()).toList(),
    );
    await _prefs.setString(_vouchersKey, vouchersJson);
  }

  Future<void> useVoucher(String voucherId) async {
    final vouchers = await getVouchers();
    final Voucher? voucher = vouchers.firstWhereOrNull((v) => v.id == voucherId);
    if (voucher != null && !voucher.isUsed && !voucher.isExpired) {
      voucher.markAsUsed();
      await saveVouchers(vouchers);
    }
  }

  List<Voucher> getUsedVouchers(List<Voucher> vouchers) {
    return vouchers.where((v) => v.isUsed).toList();
  }

  List<Voucher> getActiveVouchers(List<Voucher> vouchers) {
    return vouchers.where((v) => !v.isUsed && !v.isExpired).toList();
  }

  Future<void> generateInitialVouchers() async {
    final List<Voucher> initialVouchers = [
      Voucher(
        id: 'FOOD50',
        category: 'Food',
        discountPercentage: 50,
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        terms: 'Valid for all food items. Cannot be combined with other promos.',
        minPurchase: 50000,
        maxDiscount: 25000,
      ),
      Voucher(
        id: 'SHOP30',
        category: 'Shopping',
        discountPercentage: 30,
        expiryDate: DateTime.now().add(const Duration(days: 14)),
        terms: 'Valid for all shopping items.',
        minPurchase: 100000,
        maxDiscount: 50000,
      ),
      Voucher(
        id: 'TRAVEL20',
        category: 'Travel',
        discountPercentage: 20,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        terms: 'Valid for all travel bookings.',
        minPurchase: 200000,
        maxDiscount: 100000,
      ),
    ];

    await saveVouchers(initialVouchers);
  }
}
