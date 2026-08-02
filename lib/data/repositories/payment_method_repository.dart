import 'package:sqflite/sqflite.dart';

import '../models/payment_method.dart';

class PaymentMethodRepository {
  PaymentMethodRepository(this._db);
  final Database _db;

  Future<List<PaymentMethod>> getAll() async {
    final rows = await _db.query('payment_methods', orderBy: 'sort_order ASC');
    return rows.map(PaymentMethod.fromMap).toList();
  }

  Future<int> count() async {
    final r = await _db.rawQuery('SELECT COUNT(*) c FROM payment_methods');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> upsert(PaymentMethod m) async {
    await _db.insert('payment_methods', m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    await _db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }
}
