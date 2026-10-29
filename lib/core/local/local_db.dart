import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight on-device document database (persisted in SharedPreferences).
///
/// It mirrors the small subset of the Firestore API the app's services use
/// (collections, documents, simple queries, streams, transactions) so that all
/// data lives only on the device.

// ============================================
// Value types
// ============================================

/// Point in time stored in documents.
class Timestamp implements Comparable<Timestamp> {
  final int millisecondsSinceEpoch;

  const Timestamp._(this.millisecondsSinceEpoch);

  factory Timestamp.fromDate(DateTime date) =>
      Timestamp._(date.millisecondsSinceEpoch);

  factory Timestamp.now() => Timestamp.fromDate(DateTime.now());

  DateTime toDate() => DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch,
      );

  @override
  int compareTo(Timestamp other) =>
      millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);

  @override
  bool operator ==(Object other) =>
      other is Timestamp &&
      other.millisecondsSinceEpoch == millisecondsSinceEpoch;

  @override
  int get hashCode => millisecondsSinceEpoch.hashCode;
}

/// Sentinel values resolved when a document is written.
class FieldValue {
  final String _kind;
  final num _amount;

  const FieldValue._(this._kind, [this._amount = 0]);

  static FieldValue serverTimestamp() => const FieldValue._('timestamp');

  static FieldValue increment(num amount) => FieldValue._('increment', amount);
}

class LocalDbException implements Exception {
  final String message;
  const LocalDbException(this.message);

  @override
  String toString() => 'LocalDbException: $message';
}

// ============================================
// Session (which user's data is active)
// ============================================

class LocalUser {
  final String uid;
  const LocalUser(this.uid);
}

class LocalAuth {
  LocalAuth._();
  static final LocalAuth instance = LocalAuth._();

  String? _uid;

  LocalUser? get currentUser => _uid == null ? null : LocalUser(_uid!);

  void setUid(String? uid) => _uid = uid;
}

// ============================================
// Database
// ============================================

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static const String _prefsKey = 'local_db_v1';

  // collectionPath -> docId -> encoded document
  Map<String, Map<String, Map<String, dynamic>>> _data = {};
  final StreamController<String> _changes = StreamController.broadcast();
  int _idCounter = 0;

  /// Loads persisted data. Call once before runApp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _data = decoded.map(
        (path, docs) => MapEntry(
          path,
          (docs as Map<String, dynamic>).map(
            (id, doc) => MapEntry(id, Map<String, dynamic>.from(doc as Map)),
          ),
        ),
      );
    } catch (_) {
      _data = {};
    }
  }

  Future<void> _persist(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_data));
    _changes.add(path);
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${(_idCounter++).toRadixString(36)}';

  CollectionReference collection(String name) =>
      CollectionReference._(this, name);

  /// Runs [handler]; writes made through the transaction are applied after it
  /// completes.
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) handler,
  ) async {
    final txn = Transaction._();
    final result = await handler(txn);
    for (final write in txn._writes) {
      await write();
    }
    return result;
  }

  // ---- encoding ----

  static dynamic _encode(dynamic v) {
    if (v is Timestamp) return {'__ts': v.millisecondsSinceEpoch};
    if (v is DateTime) return {'__ts': v.millisecondsSinceEpoch};
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _encode(val)));
    }
    if (v is List) return v.map(_encode).toList();
    return v;
  }

  static dynamic _decode(dynamic v) {
    if (v is Map) {
      if (v.length == 1 && v.containsKey('__ts')) {
        return Timestamp._(v['__ts'] as int);
      }
      return v.map((k, val) => MapEntry(k.toString(), _decode(val)));
    }
    if (v is List) return v.map(_decode).toList();
    return v;
  }

  Map<String, dynamic> _resolve(
    Map<String, dynamic> input,
    Map<String, dynamic>? existing,
  ) {
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      if (value is FieldValue) {
        if (value._kind == 'timestamp') {
          out[key] = _encode(Timestamp.now());
        } else {
          final current = existing?[key];
          final base = current is num ? current : 0;
          out[key] = base + value._amount;
        }
      } else {
        out[key] = _encode(value);
      }
    });
    return out;
  }
}

// ============================================
// Snapshots
// ============================================

class DocumentSnapshot {
  final String id;
  final Map<String, dynamic>? _data;

  DocumentSnapshot._(this.id, this._data);

  bool get exists => _data != null;

  Map<String, dynamic> data() => _data ?? const {};
}

class QueryDocumentSnapshot extends DocumentSnapshot {
  QueryDocumentSnapshot._(super.id, Map<String, dynamic> super.data)
      : super._();
}

class QuerySnapshot {
  final List<QueryDocumentSnapshot> docs;
  QuerySnapshot._(this.docs);
}

class AggregateQuerySnapshot {
  final int? count;
  AggregateQuerySnapshot._(this.count);
}

class AggregateQuery {
  final Query _query;
  AggregateQuery._(this._query);

  Future<AggregateQuerySnapshot> get() async =>
      AggregateQuerySnapshot._(_query._run().length);
}

// ============================================
// Queries / references
// ============================================

class _Filter {
  final String field;
  final String op;
  final dynamic value;
  const _Filter(this.field, this.op, this.value);
}

class Query {
  final LocalDb _db;
  final String _path;
  final List<_Filter> _filters;
  final String? _orderField;
  final bool _descending;

  Query._(
    this._db,
    this._path, [
    this._filters = const [],
    this._orderField,
    this._descending = false,
  ]);

  Query where(
    String field, {
    Object? isEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
  }) {
    final filters = [..._filters];
    if (isEqualTo != null) filters.add(_Filter(field, '==', isEqualTo));
    if (isGreaterThan != null) filters.add(_Filter(field, '>', isGreaterThan));
    if (isGreaterThanOrEqualTo != null) {
      filters.add(_Filter(field, '>=', isGreaterThanOrEqualTo));
    }
    if (isLessThan != null) filters.add(_Filter(field, '<', isLessThan));
    if (isLessThanOrEqualTo != null) {
      filters.add(_Filter(field, '<=', isLessThanOrEqualTo));
    }
    return Query._(_db, _path, filters, _orderField, _descending);
  }

  Query orderBy(String field, {bool descending = false}) =>
      Query._(_db, _path, _filters, field, descending);

  static int _compare(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is Timestamp && b is Timestamp) return a.compareTo(b);
    if (a is num && b is num) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }

  bool _matches(Map<String, dynamic> doc) {
    for (final f in _filters) {
      final v = doc[f.field];
      final c = _compare(v, f.value);
      switch (f.op) {
        case '==':
          if (v == null || c != 0) return false;
        case '>':
          if (v == null || c <= 0) return false;
        case '>=':
          if (v == null || c < 0) return false;
        case '<':
          if (v == null || c >= 0) return false;
        case '<=':
          if (v == null || c > 0) return false;
      }
    }
    return true;
  }

  List<QueryDocumentSnapshot> _run() {
    final docs = _db._data[_path] ?? const {};
    final list = <QueryDocumentSnapshot>[];
    docs.forEach((id, raw) {
      final decoded = LocalDb._decode(raw) as Map<String, dynamic>;
      if (_matches(decoded)) list.add(QueryDocumentSnapshot._(id, decoded));
    });
    final field = _orderField;
    if (field != null) {
      list.sort((a, b) {
        final c = _compare(a.data()[field], b.data()[field]);
        return _descending ? -c : c;
      });
    }
    return list;
  }

  Future<QuerySnapshot> get() async => QuerySnapshot._(_run());

  AggregateQuery count() => AggregateQuery._(this);

  Stream<QuerySnapshot> snapshots() {
    late StreamController<QuerySnapshot> controller;
    StreamSubscription<String>? sub;
    controller = StreamController<QuerySnapshot>(
      onListen: () {
        controller.add(QuerySnapshot._(_run()));
        sub = _db._changes.stream.where((p) => p == _path).listen((_) {
          controller.add(QuerySnapshot._(_run()));
        });
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }
}

class CollectionReference extends Query {
  CollectionReference._(super.db, super.path) : super._();

  DocumentReference doc([String? id]) =>
      DocumentReference._(_db, _path, id ?? _db._newId());

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final ref = doc();
    await ref.set(data);
    return ref;
  }
}

class DocumentReference {
  final LocalDb _db;
  final String _collectionPath;
  final String id;

  DocumentReference._(this._db, this._collectionPath, this.id);

  CollectionReference collection(String name) =>
      CollectionReference._(_db, '$_collectionPath/$id/$name');

  Future<DocumentSnapshot> get() async {
    final raw = _db._data[_collectionPath]?[id];
    return DocumentSnapshot._(
      id,
      raw == null ? null : LocalDb._decode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> set(Map<String, dynamic> data) async {
    final docs = _db._data.putIfAbsent(_collectionPath, () => {});
    docs[id] = _db._resolve(data, docs[id]);
    await _db._persist(_collectionPath);
  }

  Future<void> update(Map<String, dynamic> data) async {
    final docs = _db._data[_collectionPath];
    final existing = docs?[id];
    if (docs == null || existing == null) {
      throw const LocalDbException('Document not found');
    }
    docs[id] = {...existing, ..._db._resolve(data, existing)};
    await _db._persist(_collectionPath);
  }

  Future<void> delete() async {
    final docs = _db._data[_collectionPath];
    if (docs == null || docs.remove(id) == null) return;
    await _db._persist(_collectionPath);
  }
}

class Transaction {
  final List<Future<void> Function()> _writes = [];

  Transaction._();

  Future<DocumentSnapshot> get(DocumentReference ref) => ref.get();

  void update(DocumentReference ref, Map<String, dynamic> data) {
    _writes.add(() => ref.update(data));
  }
}

