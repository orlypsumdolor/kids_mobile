import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'checkin_app.db';
  static const int _databaseVersion = 1;

  static Future<Database> initializeDatabase() async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );

    return _database!;
  }

  static Future<void> _createDatabase(Database db, int version) async {
    // Children table
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        qr_code TEXT UNIQUE NOT NULL,
        rfid_code TEXT UNIQUE NOT NULL,
        guardian_first_name TEXT NOT NULL,
        guardian_last_name TEXT NOT NULL,
        guardian_phone TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        date_of_birth TEXT NOT NULL,
        allergies TEXT,
        medical_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Checkin sessions table
    await db.execute('''
      CREATE TABLE checkin_sessions (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        volunteer_id TEXT NOT NULL,
        service_session TEXT NOT NULL,
        pickup_code TEXT NOT NULL,
        checkin_time TEXT NOT NULL,
        checkout_time TEXT,
        status TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (child_id) REFERENCES children (id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_children_qr_code ON children (qr_code)');
    await db.execute('CREATE INDEX idx_children_rfid_code ON children (rfid_code)');
    await db.execute('CREATE INDEX idx_sessions_child_id ON checkin_sessions (child_id)');
    await db.execute('CREATE INDEX idx_sessions_pickup_code ON checkin_sessions (pickup_code)');
    await db.execute('CREATE INDEX idx_sessions_status ON checkin_sessions (status)');
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