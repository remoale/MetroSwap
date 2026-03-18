import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:metroswap/firebase_options.dart';

/// Sincroniza el estado en línea de cada usuario con Realtime Database.
class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSubscription;
  DatabaseReference? _connectedRef;
  StreamSubscription<DatabaseEvent>? _connectedSubscription;
  OnDisconnect? _onDisconnect;
  DatabaseReference? _statusRef;
  String? _activeUid;
  bool _initialized = false;

  FirebaseDatabase get _database => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.realtimeDatabaseUrl,
      );

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
  }

  Future<void> dispose() async {
    await _connectedSubscription?.cancel();
    await _authSubscription?.cancel();
    _connectedSubscription = null;
    _authSubscription = null;
    _connectedRef = null;
    _onDisconnect = null;
    _statusRef = null;
    _activeUid = null;
    _initialized = false;
  }

  Stream<UserPresence> watchUserPresence(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream<UserPresence>.value(const UserPresence.offline());
    }

    return _database.ref('status/$normalizedUid').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map<Object?, Object?>) {
        final normalizedMap = value.map(
          (key, mapValue) => MapEntry(key.toString(), mapValue),
        );
        return UserPresence.fromMap(normalizedMap);
      }
      return const UserPresence.offline();
    });
  }

  Future<void> markCurrentUserOffline() async {
    if (_activeUid == null) return;
    await _setOffline(_activeUid!);
  }

  Future<void> _handleAuthChanged(User? user) async {
    final nextUid = user?.uid.trim();
    final previousUid = _activeUid;

    if (previousUid != null && previousUid.isNotEmpty && previousUid != nextUid) {
      await _setOffline(previousUid);
    }

    await _connectedSubscription?.cancel();
    _connectedSubscription = null;
    _connectedRef = null;
    _onDisconnect = null;
    _statusRef = null;
    _activeUid = null;

    if (nextUid == null || nextUid.isEmpty) {
      return;
    }

    _activeUid = nextUid;
    _statusRef = _database.ref('status/$nextUid');
    _connectedRef = _database.ref('.info/connected');
    _onDisconnect = _statusRef!.onDisconnect();

    _connectedSubscription = _connectedRef!.onValue.listen((event) async {
      final isConnected = event.snapshot.value == true;
      if (!isConnected || _statusRef == null) return;

      await _onDisconnect?.set(_offlinePayload());
      await _statusRef!.set(_onlinePayload());
    });
  }

  Future<void> _setOffline(String uid) async {
    try {
      await _database.ref('status/$uid').set(_offlinePayload());
    } catch (error, stackTrace) {
      debugPrint('No se pudo marcar offline a $uid: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Map<String, Object> _onlinePayload() {
    return <String, Object>{
      'state': 'online',
      'lastChanged': ServerValue.timestamp,
    };
  }

  Map<String, Object> _offlinePayload() {
    return <String, Object>{
      'state': 'offline',
      'lastChanged': ServerValue.timestamp,
    };
  }
}

class UserPresence {
  final bool isOnline;
  final DateTime? lastSeen;

  const UserPresence({
    required this.isOnline,
    required this.lastSeen,
  });

  const UserPresence.offline()
      : isOnline = false,
        lastSeen = null;

  factory UserPresence.fromMap(Map<String, Object?> data) {
    final state = (data['state'] ?? '').toString().trim().toLowerCase();
    final rawLastChanged = data['lastChanged'];
    DateTime? lastSeen;

    if (rawLastChanged is int) {
      lastSeen = DateTime.fromMillisecondsSinceEpoch(rawLastChanged);
    } else if (rawLastChanged is double) {
      lastSeen = DateTime.fromMillisecondsSinceEpoch(rawLastChanged.toInt());
    } else if (rawLastChanged is String) {
      final parsed = int.tryParse(rawLastChanged);
      if (parsed != null) {
        lastSeen = DateTime.fromMillisecondsSinceEpoch(parsed);
      }
    }

    return UserPresence(
      isOnline: state == 'online',
      lastSeen: lastSeen,
    );
  }
}
