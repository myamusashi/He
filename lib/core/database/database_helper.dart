import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finansa.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // ══════════════════════════════════════════
  // CREATE DATABASE
  // ══════════════════════════════════════════
  Future _createDB(Database db, int version) async {
    // Tabel kategori
    await db.execute('''
      CREATE TABLE categories (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT    NOT NULL,
        icon         TEXT    NOT NULL,
        color        INTEGER NOT NULL,
        budget_limit REAL    DEFAULT 0
      )
    ''');

    // Tabel transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        amount        REAL    NOT NULL,
        type          TEXT    NOT NULL,
        category_id   INTEGER,
        category_name TEXT,
        category_icon TEXT,
        date          TEXT    NOT NULL,
        note          TEXT,
        emotion_type  TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Tabel goals
    await db.execute('''
      CREATE TABLE goals (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        title          TEXT NOT NULL,
        target_amount  REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline       TEXT,
        created_at     TEXT NOT NULL
      )
    ''');

    await _insertDefaultCategories(db);
  }

  // ══════════════════════════════════════════
  // UPGRADE DATABASE
  // ══════════════════════════════════════════
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN category_name TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN category_icon TEXT',
        );
      } catch (_) {}
    }
  }

  // ══════════════════════════════════════════
  // DEFAULT CATEGORIES
  // ══════════════════════════════════════════
  Future _insertDefaultCategories(Database db) async {
    final categories = [
      {'name': 'Makanan & Minum', 'icon': '🍔', 'color': 0xFFE53935},
      {'name': 'Transportasi', 'icon': '🚗', 'color': 0xFF1E88E5},
      {'name': 'Belanja', 'icon': '🛍️', 'color': 0xFF8E24AA},
      {'name': 'Hiburan', 'icon': '🎮', 'color': 0xFFFF7043},
      {'name': 'Pendidikan', 'icon': '📚', 'color': 0xFF43A047},
      {'name': 'Kesehatan', 'icon': '💊', 'color': 0xFF00ACC1},
      {'name': 'Tagihan', 'icon': '📱', 'color': 0xFFF57F17},
      {'name': 'Gaji', 'icon': '💰', 'color': 0xFF43A047},
      {'name': 'Lainnya', 'icon': '💸', 'color': 0xFF9E9E9E},
    ];

    for (var cat in categories) {
      await db.insert('categories', {
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'budget_limit': 0,
      });
    }
  }

  // ══════════════════════════════════════════
  // CRUD TRANSAKSI
  // ══════════════════════════════════════════

  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    // Hanya insert kolom yang ada di tabel
    return await db.insert('transactions', {
      'amount': data['amount'],
      'type': data['type'],
      'category_id': data['category_id'],
      'category_name': data['category_name'],
      'category_icon': data['category_icon'],
      'date': data['date'],
      'note': data['note'],
      'emotion_type': data['emotion_type'],
    });
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        t.*,
        COALESCE(t.category_name, c.name) as category_name,
        COALESCE(t.category_icon, c.icon) as category_icon,
        c.color as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      ORDER BY t.date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions(
      {int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        t.*,
        COALESCE(t.category_name, c.name) as category_name,
        COALESCE(t.category_icon, c.icon) as category_icon,
        c.color as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      ORDER BY t.date DESC
      LIMIT $limit
    ''');
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllTransactions() async {
    final db = await database;
    return await db.delete('transactions');
  }

  // ══════════════════════════════════════════
  // SUMMARY
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> getSummary() async {
    final db = await database;

    final income = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income'",
    );
    final expense = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense'",
    );

    final double totalIncome = (income.first['total'] as num).toDouble();
    final double totalExpense = (expense.first['total'] as num).toDouble();

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  // ══════════════════════════════════════════
  // ANALYTICS
  // ══════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getExpenseByEmotion() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT emotion_type, SUM(amount) as total
      FROM transactions
      WHERE type = 'expense'
        AND emotion_type IS NOT NULL
      GROUP BY emotion_type
      ORDER BY total DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getLast30DaysTransactions() async {
    final db = await database;
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    return await db.rawQuery('''
      SELECT date, type, amount, emotion_type
      FROM transactions
      WHERE date >= ?
      ORDER BY date ASC
    ''', [thirtyDaysAgo]);
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        COALESCE(t.category_name, c.name) as name,
        COALESCE(t.category_icon, c.icon) as icon,
        c.color,
        SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'expense'
      GROUP BY t.category_id
      ORDER BY total DESC
    ''');
  }

  // ══════════════════════════════════════════
  // CATEGORIES
  // ══════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<int> updateBudgetLimit(int categoryId, double limit) async {
    final db = await database;
    return await db.update(
      'categories',
      {'budget_limit': limit},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<List<Map<String, dynamic>>> getBudgetVsActual() async {
    final db = await database;
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1).toIso8601String();
    return await db.rawQuery('''
      SELECT
        c.id,
        c.name,
        c.icon,
        c.color,
        c.budget_limit,
        COALESCE(SUM(t.amount), 0) as actual_spent
      FROM categories c
      LEFT JOIN transactions t
        ON  t.category_id = c.id
        AND t.type = 'expense'
        AND t.date >= ?
      GROUP BY c.id
      ORDER BY actual_spent DESC
    ''', [firstDay]);
  }

  // ══════════════════════════════════════════
  // GOALS
  // ══════════════════════════════════════════

  Future<int> insertGoal(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('goals', data);
  }

  Future<List<Map<String, dynamic>>> getAllGoals() async {
    final db = await database;
    return await db.query('goals', orderBy: 'created_at DESC');
  }

  Future<int> updateGoalAmount(int id, double amount) async {
    final db = await database;
    return await db.update(
      'goals',
      {'current_amount': amount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllGoals() async {
    final db = await database;
    return await db.delete('goals');
  }

  // ══════════════════════════════════════════
  // RESET ALL
  // ══════════════════════════════════════════

  Future<void> resetAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('goals');
    await db.update('categories', {'budget_limit': 0});
  }

  // ══════════════════════════════════════════
  // CLOSE
  // ══════════════════════════════════════════

  Future close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
