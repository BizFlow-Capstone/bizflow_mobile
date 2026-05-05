import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'db_config.dart';

import 'daos/api_cache_dao.dart';
import 'daos/imports_dao.dart';
import 'daos/invoice_template_settings_dao.dart';
import 'daos/locations_dao.dart';
import 'daos/employees_dao.dart';
import 'daos/orders_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sync_state_dao.dart';
import 'tables/api_cache_entries_table.dart';
import 'tables/imports_table.dart';
import 'tables/invoice_template_settings_table.dart';
import 'tables/employees_table.dart';
import 'tables/locations_table.dart';
import 'tables/orders_table.dart';
import 'tables/products_table.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocationsTable,
    ProductsTable,
    EmployeesTable,
    OrdersTable,
    ImportsTable,
    ApiCacheEntriesTable,
    InvoiceTemplateSettingsTable,
    SyncStateTable,
  ],
  daos: [
    LocationsDao,
    ProductsDao,
    EmployeesDao,
    OrdersDao,
    ImportsDao,
    ApiCacheDao,
    InvoiceTemplateSettingsDao,
    SyncStateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.executor);

  static AppDatabase? _instance;
  static String _activeDbFileName = DbConfig.defaultDbFileName;
  static Future<Directory> Function() _documentsDirectoryProvider =
      getApplicationDocumentsDirectory;
  static Future<void> Function()? _debugOpenVerificationHook;

  factory AppDatabase() => _instance ??= _create(_activeDbFileName);

  static String get activeDbFileName => _activeDbFileName;

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(productsTable);
      }
      if (from < 3) {
        await m.createTable(employeesTable);
      }
      if (from < 4) {
        await m.createTable(apiCacheEntriesTable);
      }
      if (from < 5) {
        await m.createTable(invoiceTemplateSettingsTable);
      }
      if (from < 6) {
        await m.createTable(ordersTable);
      }
      if (from < 7) {
        await m.createTable(importsTable);
      }
      if (from < 8) {
        await m.addColumn(productsTable, productsTable.trackInventory);
      }
      if (from < 9) {
        await m.addColumn(ordersTable, ordersTable.createdByProfileId);
        await m.addColumn(ordersTable, ordersTable.createdByProfileFullName);
      }
    },
  );

  Future<void> ensureInitialized() async {
    await customSelect('SELECT 1').getSingle();
  }

  Future<bool> verifyWalMode() async {
    final current = await _readJournalMode();
    if (current == 'wal') {
      return true;
    }

    await customStatement('PRAGMA journal_mode = WAL;');
    final updated = await _readJournalMode();
    return updated == 'wal';
  }

  Future<String> _readJournalMode() async {
    final row = await customSelect('PRAGMA journal_mode;').getSingle();
    final raw = row.data.values.isEmpty ? null : row.data.values.first;
    return (raw?.toString() ?? '').toLowerCase();
  }

  Future<void> clearUserScopedData() async {
    await transaction(() async {
      await locationsDao.clearAll();
      await productsDao.clearAll();
      await employeesDao.clearAll();
      await ordersDao.clearAll();
      await importsDao.clearAll();
      await apiCacheDao.clearAll();
      await syncStateDao.clearAll();
    });
  }

  static Future<void> reconfigureForUserScope(
    String? userScope, {
    bool forceReopen = false,
  }) async {
    final targetFileName = DbConfig.databaseFileNameForUser(userScope);
    final shouldUseBackup = forceReopen;

    if (!forceReopen && _instance != null && _activeDbFileName == targetFileName) {
      return;
    }

    final previous = _instance;
    if (previous != null) {
      await previous.close();
      _instance = null;
    }

    final dbFile = await _resolveDatabaseFile(targetFileName);
    final backupFile = File('${dbFile.path}.bak');

    if (shouldUseBackup && await dbFile.exists()) {
      await dbFile.copy(backupFile.path);
    }

    try {
      final next = await _openAndVerify(targetFileName);
      _instance = next;
      _activeDbFileName = targetFileName;
      if (shouldUseBackup && await backupFile.exists()) {
        await backupFile.delete();
      }
      return;
    } catch (_) {
      // Continue to rollback/self-heal flow below.
    }

    // Rollback path: restore from backup and verify once again.
    if (shouldUseBackup && await backupFile.exists()) {
      try {
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        await backupFile.copy(dbFile.path);

        final rollback = await _openAndVerify(targetFileName);
        _instance = rollback;
        _activeDbFileName = targetFileName;
        await backupFile.delete();
        return;
      } catch (_) {
        // Fallthrough to self-healing.
      }
    }

    // Self-healing path: rebuild from scratch.
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    if (shouldUseBackup && await backupFile.exists()) {
      await backupFile.delete();
    }

    final healed = await _openAndVerify(targetFileName);
    _instance = healed;
    _activeDbFileName = targetFileName;
  }

  static AppDatabase _create(String fileName) {
    return AppDatabase._internal(_openConnection(fileName));
  }

  static Future<AppDatabase> _openAndVerify(String fileName) async {
    final next = _create(fileName);
    try {
      if (_debugOpenVerificationHook != null) {
        await _debugOpenVerificationHook!.call();
      }
      await next.ensureInitialized();
      return next;
    } catch (error) {
      await next.close();
      rethrow;
    }
  }

  static Future<File> _resolveDatabaseFile(String fileName) async {
    final dir = await _documentsDirectoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  @visibleForTesting
  static void setDocumentsDirectoryProviderForTesting(
    Future<Directory> Function() provider,
  ) {
    _documentsDirectoryProvider = provider;
  }

  @visibleForTesting
  static void setOpenVerificationHookForTesting(Future<void> Function()? hook) {
    _debugOpenVerificationHook = hook;
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    if (_instance != null) {
      await _instance!.close();
    }
    _instance = null;
    _activeDbFileName = DbConfig.defaultDbFileName;
    _documentsDirectoryProvider = getApplicationDocumentsDirectory;
    _debugOpenVerificationHook = null;
  }
}

LazyDatabase _openConnection(String fileName) {
  return LazyDatabase(() async {
    final dir = await AppDatabase._documentsDirectoryProvider();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // WAL improves concurrent read/write behavior for local-first sync flows.
        db.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}
