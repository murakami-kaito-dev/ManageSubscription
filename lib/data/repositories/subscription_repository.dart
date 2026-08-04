import 'package:sqflite/sqflite.dart';

import '../models/subscription.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._db);
  final Database _db;

  Future<List<Subscription>> getAll() async {
    final rows = await _db.query('subscriptions', orderBy: 'sort_order ASC, created_at ASC');
    return rows.map(Subscription.fromMap).toList();
  }

  Future<int> count() async {
    final r = await _db.rawQuery('SELECT COUNT(*) c FROM subscriptions');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> upsert(Subscription s) async {
    await _db.insert('subscriptions', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Batch-insert many subscriptions (used by CSV import). Additive: fresh IDs
  /// mean existing rows are never overwritten.
  Future<void> upsertAll(List<Subscription> subs) async {
    if (subs.isEmpty) return;
    final batch = _db.batch();
    for (final s in subs) {
      batch.insert('subscriptions', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(String id) async {
    await _db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPaused(String id, bool paused) async {
    await _db.update('subscriptions', {'is_paused': paused ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Persist a manual reorder (list already in desired order).
  Future<void> saveOrder(List<Subscription> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update('subscriptions', {'sort_order': i},
          where: 'id = ?', whereArgs: [ordered[i].id]);
    }
    await batch.commit(noResult: true);
  }
}
