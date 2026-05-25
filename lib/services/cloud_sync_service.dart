import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/medicine.dart';
import 'local_store.dart';

class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  final _db = FirebaseFirestore.instance;
  final _connectivity = Connectivity();

  Future<bool> _online() async {

    final result =
    await _connectivity.checkConnectivity();

    return result !=
        ConnectivityResult.none;
  }

  CollectionReference<Map<String, dynamic>>? _col() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('medicines');
  }

  Future<void> pushMedicine(Medicine m) async {
    if (!await _online()) return;
    final col = _col();
    if (col == null) return;
    await col.doc(m.id).set(m.toMap());
  }

  Future<void> deleteRemoteMedicine(String id) async {
    if (!await _online()) return;
    final col = _col();
    if (col == null) return;
    await col.doc(id).delete();
  }

  Future<void> mergeFromCloud() async {
    if (!await _online()) return;
    final col = _col();
    if (col == null) return;

    final snapshot = await col.get();
    final local = LocalStore.readMedicines();
    final byId = {for (final m in local) m.id: m};

    for (final doc in snapshot.docs) {
      final remote = Medicine.fromMap({...doc.data(), 'id': doc.id});
      final prev = byId[remote.id];
      if (prev == null || remote.createdAt.isAfter(prev.createdAt)) {
        byId[remote.id] = remote;
      }
    }

    for (final m in byId.values) {
      await LocalStore.upsertMedicine(m);
    }
  }
}