import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/disease_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _db;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _db = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shambadoc.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scans (
            id TEXT PRIMARY KEY,
            image_path TEXT NOT NULL,
            disease_name TEXT NOT NULL,
            crop_type TEXT,
            confidence REAL NOT NULL,
            confidence_tier TEXT,
            severity TEXT,
            description TEXT,
            treatment TEXT,
            dosage TEXT,
            timestamp TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            farm_note TEXT,
            plot_name TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfMissing(db, 'scans', 'crop_type', 'TEXT');
          await _addColumnIfMissing(db, 'scans', 'confidence_tier', 'TEXT');
          await _addColumnIfMissing(db, 'scans', 'severity', 'TEXT');
          await _addColumnIfMissing(db, 'scans', 'description', 'TEXT');
          await _addColumnIfMissing(db, 'scans', 'treatment', 'TEXT');
          await _addColumnIfMissing(db, 'scans', 'dosage', 'TEXT');
          await _addColumnIfMissing(db, 'scans', 'plot_name', 'TEXT');
        }
      },
    );
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String type) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> saveScan(ScanResult scan) async {
    if (_db == null) throw Exception('Database not initialized');
    await _db!.insert('scans', scan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScanResult>> getScanHistory() async {
    if (_db == null) return [];
    final maps = await _db!.query('scans', orderBy: 'timestamp DESC');
    return maps.map((map) => ScanResult(
      id: map['id'] as String,
      imagePath: map['image_path'] as String,
      disease: DiseaseModel(
        name: map['disease_name'] as String,
        confidence: (map['confidence'] as num).toDouble(),
        description: map['description'] as String? ?? '',
        treatment: map['treatment'] as String? ?? '',
        dosage: map['dosage'] as String? ?? '',
        cropType: map['crop_type'] as String? ?? 'Unknown',
        severity: map['severity'] as String? ?? 'moderate',
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      farmNote: map['farm_note'] as String?,
      plotName: map['plot_name'] as String?,
    )).toList();
  }

  Future<void> deleteScan(String id) async {
    if (_db == null) return;
    await _db!.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setLanguage(String lang) async {
    await _prefs?.setString('language', lang);
  }

  String getLanguage() => _prefs?.getString('language') ?? 'en';

  Future<void> setOfflineMode(bool enabled) async {
    await _prefs?.setBool('offline_mode', enabled);
  }

  bool getOfflineMode() => _prefs?.getBool('offline_mode') ?? true;
}
