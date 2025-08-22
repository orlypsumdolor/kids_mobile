import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'checkin_app.db';
  static const int _databaseVersion = 3;

  static Future<Database> initializeDatabase() async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    // For testing: delete existing database to force recreation with new schema
    // Remove this in production
    try {
      await databaseFactory.deleteDatabase(path);
      print('Deleted existing database to force recreation');
    } catch (e) {
      print('No existing database to delete: $e');
    }

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  static Future<void> _createDatabase(Database db, int version) async {
    // Children table
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        date_of_birth TEXT,
        gender TEXT,
        age_group TEXT,
        guardian_id TEXT,
        emergency_contact TEXT,
        special_notes TEXT,
        qr_code TEXT,
        rfid_tag TEXT,
        is_active INTEGER DEFAULT 1,
        currently_checked_in INTEGER DEFAULT 0,
        last_check_in TEXT,
        last_check_out TEXT,
        created_by TEXT,
        updated_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Checkin sessions table
    await db.execute('''
      CREATE TABLE checkin_sessions (
        id TEXT PRIMARY KEY,
        service_session_id TEXT NOT NULL,
        date TEXT NOT NULL,
        created_by TEXT NOT NULL,
        checked_in_children TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        pickup_code TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_children_qr_code ON children (qr_code)');
    await db
        .execute('CREATE INDEX idx_children_rfid_tag ON children (rfid_tag)');
    await db.execute(
        'CREATE INDEX idx_sessions_service_session ON checkin_sessions (service_session_id)');
    await db.execute(
        'CREATE INDEX idx_sessions_pickup_code ON checkin_sessions (pickup_code)');
    await db.execute(
        'CREATE INDEX idx_sessions_active ON checkin_sessions (is_active)');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    print('Database upgrade: $oldVersion -> $newVersion');

    if (oldVersion < 2) {
      print('Upgrading from version 1: Dropping old tables');
      // Drop old tables and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS children');
      await db.execute('DROP TABLE IF EXISTS checkin_sessions');

      // Recreate tables with new schema
      await _createDatabase(db, newVersion);
    }

    if (oldVersion < 3) {
      print('Upgrading from version 2: Recreating tables with correct schema');
      // Drop and recreate tables to ensure correct schema
      await db.execute('DROP TABLE IF EXISTS children');
      await db.execute('DROP TABLE IF EXISTS checkin_sessions');

      // Recreate tables with new schema
      await _createDatabase(db, newVersion);
    }
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await initializeDatabase();
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await initializeDatabase();
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await initializeDatabase();
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await initializeDatabase();
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
}
