import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// An Offline-First Synchronization Service for Oummi.
/// 
/// How it works:
/// 1. Saves every write operation to a local Hive box (`pending_sync_v1`).
/// 2. Listens for internet connectivity changes using `connectivity_plus`.
/// 3. When online, it batches all pending writes and pushes them to Firestore 
///    in a single atomic transaction.
class SyncService {
  static const String pendingBoxName = 'pending_sync_v1';
  late Box _pendingBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;

  /// Initializes Hive and starts the network listener.
  Future<void> init() async {
    await Hive.initFlutter();
    _pendingBox = await Hive.openBox(pendingBoxName);
    
    // Listen for connectivity changes to trigger automatic sync
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncPendingChanges();
      }
    });
  }

  /// Saves a write operation locally and attempts an immediate background sync.
  /// Used for critical medical updates and labor signals.
  Future<void> performWrite({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    String type = 'set', // 'set' or 'update'
  }) async {
    final key = '${collection}_$docId';
    
    // 1. Store in the local persistent queue (survives app restarts)
    await _pendingBox.put(key, {
      'collection': collection,
      'docId': docId,
      'data': data,
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // 2. Immediate fire-and-forget sync attempt
    await syncPendingChanges();
  }

  /// Batches up to 500 operations and sends them to Firestore using `WriteBatch`.
  Future<void> syncPendingChanges() async {
    if (_pendingBox.isEmpty) return;

    // Check current network status
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.any((r) => r == ConnectivityResult.none)) return;

    final batch = _firestore.batch();
    final keysToRemove = <String>[];
    
    // Firebase batches are limited to 500 operations to prevent timeout
    int count = 0;
    final sortedKeys = _pendingBox.keys.toList()..sort((a, b) {
      final valA = _pendingBox.get(a);
      final valB = _pendingBox.get(b);
      return (valA['timestamp'] ?? 0).compareTo(valB['timestamp'] ?? 0);
    });

    for (final key in sortedKeys) {
      if (count >= 500) break;
      
      final op = _pendingBox.get(key);
      final ref = _firestore.collection(op['collection']).doc(op['docId']);
      
      if (op['type'] == 'set') {
        batch.set(ref, op['data'], SetOptions(merge: true));
      } else {
        batch.update(ref, op['data']);
      }
      
      keysToRemove.add(key as String);
      count++;
    }

    try {
      // Perform atomic write to the cloud
      await batch.commit();
      
      // Clean up the local queue only AFTER cloud success
      for (final key in keysToRemove) {
        await _pendingBox.delete(key);
      }
      debugPrint('Sync successful: $count operations committed.');
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  /// Cleans up resources when the app is closing.
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final service = SyncService();
  await service.init();
  return service;
});
