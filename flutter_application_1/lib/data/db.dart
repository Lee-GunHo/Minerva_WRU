import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  static final AppDb _i = AppDb._();
  AppDb._();
  factory AppDb() => _i;

  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<void> resetDb() async {
    final base = await getDatabasesPath();
    final dbPath = p.join(base, 'phone.db');
    final f = File(dbPath);
    if (await f.exists()) {
      await f.delete();
      debugPrint('🗑️ Deleted old phone.db');
    }
    _db = null;
    await db; // reopen
  }

  Future<Database> _open() async {
    if (kIsWeb) throw UnsupportedError('sqflite is not supported on Web');

    final base = await getDatabasesPath();
    final dbPath = p.join(base, 'phone.db');

    return openDatabase(
      dbPath,
      version: 4, // ✅ bump to re-apply schema
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, v) async => _runInitSql(db),
      onUpgrade: (db, o, n) async => _runInitSql(db),
    );
  }

  Future<void> _runInitSql(Database d) async {
    final sql = await rootBundle.loadString('assets/db/init.sql');
    final lines = sql.split('\n');

    final buffer = StringBuffer();
    bool inTrigger = false;

    Future<void> _flush(DatabaseExecutor txn) async {
      final stmt = buffer.toString().trim();
      buffer.clear();
      if (stmt.isEmpty) return;

      final up = stmt.toUpperCase();
      if (up == 'BEGIN' ||
          up.startsWith('BEGIN TRANSACTION') ||
          up == 'COMMIT' ||
          up == 'END') {
        return; // ignore stray transaction control
      }

      try {
        await txn.execute(stmt);
      } catch (e) {
        debugPrint('⚠️ SQL error: $stmt\n$e');
        rethrow; // fail fast if schema is invalid
      }
    }

    await d.transaction((txn) async {
      for (final raw in lines) {
        final line = raw.trimRight();
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('--')) continue;

        if (!inTrigger &&
            RegExp(r'^\s*CREATE\s+TRIGGER', caseSensitive: false).hasMatch(line)) {
          inTrigger = true;
        }

        buffer.writeln(line);

        if (inTrigger) {
          if (RegExp(r'^\s*END\s*;\s*$', caseSensitive: false).hasMatch(line)) {
            await _flush(txn);
            inTrigger = false;
          }
        } else {
          if (trimmed.endsWith(';')) {
            await _flush(txn);
          }
        }
      }

      if (buffer.isNotEmpty) {
        await _flush(txn);
      }
    });
  }

  // ------------------ DAO ------------------

  Future<int> ensureSelfContact({String name = '나'}) async {
    final d = await db;
    final rows = await d.query('contacts', where: 'is_self=1', limit: 1);
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return await d.insert('contacts', {'display_name': name, 'is_self': 1});
    }

  Future<Map<String, dynamic>> ensureConversationWith(String e164) async {
    final d = await db;
    await ensureSelfContact();

    final rows = await d.rawQuery('''
      SELECT c.id AS cid
      FROM conversations c
      JOIN conversation_participants p ON p.conversation_id = c.id
      WHERE p.e164 = ?
      LIMIT 1
    ''', [e164]);

    int convId;
    if (rows.isNotEmpty) {
      convId = rows.first['cid'] as int;
    } else {
      convId = await d.insert('conversations', {'kind': 'sms'});
      final selfRow = await d.query('contacts', where: 'is_self=1', limit: 1);
      final selfId = selfRow.first['id'] as int;

      await d.insert('conversation_participants', {
        'conversation_id': convId, 'e164': e164, 'is_self': 0,
      });
      await d.insert('conversation_participants', {
        'conversation_id': convId, 'contact_id': selfId, 'is_self': 1,
      });
    }

    final me = await d.rawQuery('''
      SELECT id FROM conversation_participants
      WHERE conversation_id = ? AND is_self = 1
      LIMIT 1
    ''', [convId]);
    final myPid = me.first['id'] as int;

    final other = await d.rawQuery('''
      SELECT id FROM conversation_participants
      WHERE conversation_id = ? AND is_self = 0
      LIMIT 1
    ''', [convId]);
    final otherPid = other.first['id'] as int;

    return {'conversationId': convId, 'selfPid': myPid, 'otherPid': otherPid};
  }

  Future<void> sendMessageTo(String e164, String body) async {
    final d = await db;
    final ids = await ensureConversationWith(e164);
    final convId = ids['conversationId'] as int;
    final selfPid = ids['selfPid'] as int;

    final now = DateTime.now().millisecondsSinceEpoch;

    await d.insert('messages', {
      'conversation_id': convId,
      'sender_participant_id': selfPid,
      'body': body,
      'msg_type': 'text',
      'direction': 'outgoing',
      'status': 'sent',
      'sent_at': now,
      'risk_score': null,
    });

    await d.insert(
      'numbers',
      {
        'e164': e164,
        'is_contact': 0,
        'first_seen_at': now,
        'last_seen_at': now,
        'last_source': 'sms',
        'sms_out_cnt': 1
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await d.rawUpdate(
      'UPDATE numbers SET last_seen_at=?, sms_out_cnt=sms_out_cnt+1, last_sms_at=? WHERE e164=?',
      [now, now, e164],
    );
  }

  Future<List<ConversationRow>> fetchConversations() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT
        c.id AS cid,
        COALESCE(ct.display_name, p.e164) AS title,
        (SELECT m.body   FROM messages m WHERE m.conversation_id=c.id ORDER BY m.sent_at DESC LIMIT 1) AS last_body,
        (SELECT m.sent_at FROM messages m WHERE m.conversation_id=c.id ORDER BY m.sent_at DESC LIMIT 1) AS last_time,
        (SELECT COUNT(*) FROM messages m WHERE m.conversation_id=c.id AND m.direction='incoming' AND m.status<>'read') AS unread
      FROM conversations c
      JOIN conversation_participants p ON p.conversation_id=c.id AND p.is_self=0
      LEFT JOIN contacts ct ON ct.id=p.contact_id
      ORDER BY last_time DESC
    ''');
    return rows.map((r) => ConversationRow(
      cid: r['cid'] as int,
      title: (r['title'] as String?) ?? '대화',
      lastBody: (r['last_body'] as String?) ?? '',
      lastTimeMs: (r['last_time'] as int?) ?? 0,
      unread: (r['unread'] as int?) ?? 0,
    )).toList();
  }
}

class ConversationRow {
  final int cid;
  final String title;
  final String lastBody;
  final int lastTimeMs;
  final int unread;
  ConversationRow({
    required this.cid,
    required this.title,
    required this.lastBody,
    required this.lastTimeMs,
    required this.unread,
  });
}
