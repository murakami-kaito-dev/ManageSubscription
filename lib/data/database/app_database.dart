import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Opens (and migrates) the on-device SQLite database. Everything is local —
/// no network, no account required.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'manage_subscription.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Payment methods gained a color; existing rows default to primaryDeep.
      await db.execute(
        'ALTER TABLE payment_methods ADD COLUMN color INTEGER NOT NULL DEFAULT ${0xFF546C60}',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL DEFAULT ${0xFF546C60}
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        cycle TEXT NOT NULL,
        first_payment INTEGER NOT NULL,
        color INTEGER NOT NULL,
        emoji TEXT,
        category_id TEXT REFERENCES categories(id) ON DELETE SET NULL,
        payment_method_id TEXT REFERENCES payment_methods(id) ON DELETE SET NULL,
        memo TEXT,
        usage_count REAL NOT NULL DEFAULT 0,
        usage_unit TEXT NOT NULL DEFAULT '回',
        is_paused INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        notify_days TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await _seed(db);
  }

  /// Seed defaults so the app has sensible categories & payment methods, and a
  /// small demo of subscriptions to show off the UI on first launch.
  Future<void> _seed(Database db) async {
    final batch = db.batch();

    // 0xFF6E9080 etc — reuse the chart palette values as ints.
    // Icons reference the const IconRegistry so they resolve correctly and stay
    // tree-shakeable.
    final cats = [
      ('エンタメ', 0xFFE5977E, Icons.movie_rounded.codePoint),
      ('仕事・効率化', 0xFF7FA38C, Icons.work_rounded.codePoint),
      ('ライフスタイル', 0xFF86A9C4, Icons.spa_rounded.codePoint),
    ];
    for (var i = 0; i < cats.length; i++) {
      batch.insert('categories', {
        'id': 'cat_$i',
        'name': cats[i].$1,
        'color': cats[i].$2,
        'icon': cats[i].$3,
        'sort_order': i,
      });
    }

    final methods = [
      ('クレジットカード', Icons.credit_card_rounded.codePoint, 0xFF546C60),
      ('App Store', Icons.apple_rounded.codePoint, 0xFF6E9080),
      ('PayPay', Icons.account_balance_wallet_rounded.codePoint, 0xFFE1836B),
    ];
    for (var i = 0; i < methods.length; i++) {
      batch.insert('payment_methods', {
        'id': 'pm_$i',
        'name': methods[i].$1,
        'icon': methods[i].$2,
        'sort_order': i,
        'color': methods[i].$3,
      });
    }

    final now = DateTime.now();
    int day(int d) => DateTime(now.year, now.month, d).millisecondsSinceEpoch;

    final demos = [
      ['Netflix', 1490.0, 'JPY', 'monthly', day(15), 0xFFE5977E, '🎬', 'cat_0', 'pm_1', 8.0, '回'],
      ['Spotify', 980.0, 'JPY', 'monthly', day(3), 0xFF7FA38C, '🎵', 'cat_0', 'pm_0', 45.0, '回'],
      ['ChatGPT', 20.0, 'USD', 'monthly', day(21), 0xFF86A9C4, '🤖', 'cat_1', 'pm_0', 60.0, '回'],
      ['Amazon Prime', 5900.0, 'JPY', 'yearly', day(9), 0xFFC39BB4, '📦', 'cat_2', 'pm_0', 12.0, '回'],
      ['YouTube Premium', 1280.0, 'JPY', 'monthly', day(28), 0xFFE3C27E, '▶️', 'cat_0', 'pm_1', 30.0, '回'],
    ];
    for (var i = 0; i < demos.length; i++) {
      final d = demos[i];
      batch.insert('subscriptions', {
        'id': 'sub_seed_$i',
        'name': d[0],
        'amount': d[1],
        'currency': d[2],
        'cycle': d[3],
        'first_payment': d[4],
        'color': d[5],
        'emoji': d[6],
        'category_id': d[7],
        'payment_method_id': d[8],
        'usage_count': d[9],
        'usage_unit': d[10],
        'is_paused': 0,
        'notify_days': '1',
        'sort_order': i,
        'created_at': now.millisecondsSinceEpoch,
      });
    }

    await batch.commit(noResult: true);
  }
}
