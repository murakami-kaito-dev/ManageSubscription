import 'package:sqflite/sqflite.dart';

import '../models/category.dart';

class CategoryRepository {
  CategoryRepository(this._db);
  final Database _db;

  Future<List<Category>> getAll() async {
    final rows = await _db.query('categories', orderBy: 'sort_order ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> count() async {
    final r = await _db.rawQuery('SELECT COUNT(*) c FROM categories');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> upsert(Category c) async {
    await _db.insert('categories', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
