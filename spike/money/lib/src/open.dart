// T-002 spike: opening the database on native targets (SP-05). Kept in one
// place so the device test app needs no direct drift import.

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';

import 'schema.dart';
import 'spike_database.dart';

/// Opens (and creates or migrates) the spike database stored in [file].
SpikeDatabase openSpikeDatabase(
  File file, {
  List<Migration> migrations = schemaMigrations,
  String Function()? now,
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final executor = NativeDatabase(file);
  return now == null
      ? SpikeDatabase(executor, migrations: migrations)
      : SpikeDatabase(executor, migrations: migrations, now: now);
}
