import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const int schemaVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'bazaar.db');

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createProductTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE users ADD COLUMN theme TEXT NOT NULL DEFAULT 'system'",
          );
          await _createProductTables(db);
        }
      },
    );
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        theme TEXT NOT NULL DEFAULT 'system',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createProductTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_sw TEXT,
        category TEXT NOT NULL DEFAULT 'General',
        sku TEXT UNIQUE,
        base_unit TEXT NOT NULL DEFAULT 'kg',
        image_path TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        track_stock INTEGER NOT NULL DEFAULT 1,
        stock_qty REAL NOT NULL DEFAULT 0,
        low_stock_threshold REAL NOT NULL DEFAULT 5,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_packages (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        label TEXT NOT NULL,
        unit_type TEXT NOT NULL,
        pricing_type TEXT NOT NULL DEFAULT 'fixed',
        price REAL,
        min_price REAL,
        max_price REAL,
        base_unit_qty REAL NOT NULL DEFAULT 1,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_packages_product_id '
      'ON product_packages(product_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)',
    );
  }
}
