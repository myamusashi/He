import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService._init();

  // Ambil user ID yang sedang login
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Referensi koleksi ─────────────────────────────────────
  CollectionReference get _transactions =>
      _db.collection('users').doc(_uid).collection('transactions');

  CollectionReference get _goals =>
      _db.collection('users').doc(_uid).collection('goals');

  // ══════════════════════════════════════════
  // TRANSAKSI
  // ══════════════════════════════════════════

  // Simpan transaksi ke Firestore
  Future<void> saveTransaction(Map<String, dynamic> data) async {
    if (_uid == null) return;
    try {
      await _transactions.add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'uid': _uid,
      });
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  // Ambil semua transaksi dari Firestore
  Future<List<Map<String, dynamic>>> getTransactions() async {
    if (_uid == null) return [];
    try {
      final snapshot =
          await _transactions.orderBy('date', descending: true).get();
      return snapshot.docs
          .map((doc) =>
              {...doc.data() as Map<String, dynamic>, 'firestore_id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // Hapus transaksi dari Firestore
  Future<void> deleteTransaction(String firestoreId) async {
    if (_uid == null) return;
    try {
      await _transactions.doc(firestoreId).delete();
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  // Stream transaksi realtime
  Stream<QuerySnapshot> get transactionsStream {
    if (_uid == null) return const Stream.empty();
    return _transactions.orderBy('date', descending: true).snapshots();
  }

  // ══════════════════════════════════════════
  // SUMMARY
  // ══════════════════════════════════════════

  Future<Map<String, dynamic>> getSummary() async {
    if (_uid == null) return {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
    try {
      final snapshot = await _transactions.get();
      double income = 0;
      double expense = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num).toDouble();
        if (data['type'] == 'income') income += amount;
        if (data['type'] == 'expense') expense += amount;
      }
      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    } catch (e) {
      return {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
    }
  }

  // ══════════════════════════════════════════
  // GOALS
  // ══════════════════════════════════════════

  Future<void> saveGoal(Map<String, dynamic> data) async {
    if (_uid == null) return;
    try {
      await _goals.add(
          {...data, 'uid': _uid, 'created_at': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error saving goal: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    if (_uid == null) return [];
    try {
      final snapshot =
          await _goals.orderBy('created_at', descending: true).get();
      return snapshot.docs
          .map((doc) =>
              {...doc.data() as Map<String, dynamic>, 'firestore_id': doc.id})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteGoal(String firestoreId) async {
    if (_uid == null) return;
    try {
      await _goals.doc(firestoreId).delete();
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }

  // ══════════════════════════════════════════
  // USER PROFILE
  // ══════════════════════════════════════════

  Future<void> saveUserProfile(String name) async {
    if (_uid == null) return;
    try {
      await _db.collection('users').doc(_uid).set({
        'name': name,
        'email': FirebaseAuth.instance.currentUser?.email,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving profile: $e');
    }
  }
}
