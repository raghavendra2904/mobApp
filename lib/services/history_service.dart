import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/alarm_event.dart';

class HistoryService {
  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'neck_alert.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE alarms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            triggeredAt INTEGER NOT NULL,
            sustainedSeconds INTEGER NOT NULL,
            avgTiltDegrees REAL NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_alarms_time ON alarms(triggeredAt)');
      },
    );
    return _db!;
  }

  static Future<int> insert(AlarmEvent e) async {
    final db = await _open();
    final map = e.toMap()..remove('id');
    return db.insert('alarms', map);
  }

  static Future<List<AlarmEvent>> recent({int limit = 200}) async {
    final db = await _open();
    final rows = await db.query('alarms',
        orderBy: 'triggeredAt DESC', limit: limit);
    return rows.map(AlarmEvent.fromMap).toList();
  }

  /// Counts per day for the last [days] days. Map: dateKey (yyyy-mm-dd) -> count.
  static Future<Map<String, int>> countsByDay({int days = 14}) async {
    final db = await _open();
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final rows = await db.rawQuery(
        'SELECT triggeredAt FROM alarms WHERE triggeredAt >= ?', [since]);
    final out = <String, int>{};
    for (var i = 0; i < days; i++) {
      final d = DateTime.now().subtract(Duration(days: days - 1 - i));
      out[_key(d)] = 0;
    }
    for (final r in rows) {
      final t = DateTime.fromMillisecondsSinceEpoch(r['triggeredAt'] as int);
      final k = _key(t);
      out[k] = (out[k] ?? 0) + 1;
    }
    return out;
  }

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> clear() async {
    final db = await _open();
    await db.delete('alarms');
  }
}
