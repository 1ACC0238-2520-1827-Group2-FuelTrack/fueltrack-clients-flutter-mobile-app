import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/method.dart';
import '../models/user.dart';

class DbHelper {
  final int version = 1;
  Database? db;

  static final DbHelper _dbHelper = DbHelper._internal();

  DbHelper._internal();

  factory DbHelper() {
    return _dbHelper;
  }

  Future<Database> openDb() async {
    if (db == null) {
      db = await openDatabase(
        join(await getDatabasesPath(), 'fueltrack.db'),
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE users(id INTEGER PRIMARY KEY, accessToken TEXT, refreshToken TEXT, role TEXT)');
          await db.execute(
              'CREATE TABLE profiles(id INTEGER PRIMARY KEY, firstName TEXT, lastName TEXT, email TEXT, phone TEXT)');
          await db.execute(
              'CREATE TABLE methods(id INTEGER PRIMARY KEY, cardHolderName TEXT, lastFourDigits TEXT, cardType TEXT, expiryDate TEXT, isDefault INTEGER)');
          await db.execute(
              'CREATE TABLE notifications(id INTEGER PRIMARY KEY, title TEXT, message TEXT, type INTEGER, isRead INTEGER, relatedOrderId INTEGER, relatedOrderNumber TEXT, createdAt TEXT)');
          await db.execute(
              'CREATE TABLE orders(id INTEGER PRIMARY KEY, orderNumber TEXT, fuelType INTEGER, quantity INTEGER, pricePerLiter REAL, totalAmount REAL, status INTEGER, deliveryAddress TEXT, deliveryLatitude TEXT, deliveryLongitude TEXT, createdAt TEXT)');
          await db.execute(
              'CREATE TABLE payments(id INTEGER PRIMARY KEY, orderId INTEGER, orderNumber TEXT, amount REAL, transactionId TEXT, processedAt TEXT, createdAt TEXT, cardHolderName TEXT, lastFourDigits TEXT, cardType TEXT)');
        },
        version: version,
      );
    }
    return db!;
  }


  // PARA GUARDAR USUARIO Y USAR SUS TOKENS
  // dart
  Future<int> insertUser(User user) async {
    // Elimina todos los usuarios antes de insertar el nuevo
    await db!.delete('users');
    int id = await db!.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<int> updateUser(User user) async {
    // Si no hay usuario, inserta; si hay, actualiza
    final List<Map<String, dynamic>> maps = await db!.query('users', limit: 1);
    if (maps.isEmpty) {
      return await insertUser(user);
    }
    int result = await db!.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }


  Future<int> deleteUser() async {
    int result = await db!.delete('users');
    return result;
  }


  Future<User?> getUser() async {
    final List<Map<String, dynamic>> maps = await db!.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }


  // PARA GUARDAR METODO DE PAGO POR DEFECTO
  Future<int> insertMethod(Method method) async {
    await db!.delete('methods');
    int id = await db!.insert('methods', method.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<int> updateMethod(Method method) async {
    await db!.delete('methods');
    int id = await db!.insert('methods', method.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }



  Future<int> deleteMethod() async {
    int result = await db!.delete('methods');
    return result;
  }

  Future<Method?> getMethod() async {
    final List<Map<String, dynamic>> maps = await db!.query('methods', limit: 1);
    if (maps.isNotEmpty) {
      return Method.fromJson(maps.first);
    }
    return null;
  }





}