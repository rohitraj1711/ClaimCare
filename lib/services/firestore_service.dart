import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for Firestore database operations.
/// Provides generic CRUD operations and real-time listeners.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get Firestore instance
  FirebaseFirestore get instance => _firestore;

  /// Get a collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document reference
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  /// Create a new document with auto-generated ID
  Future<DocumentReference<Map<String, dynamic>>> create({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    return await collection(collectionPath).add(data);
  }

  /// Create a new document with a specific ID
  Future<void> createWithId({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await collection(collectionPath).doc(documentId).set(data);
  }

  /// Get a single document
  Future<DocumentSnapshot<Map<String, dynamic>>> get({
    required String collectionPath,
    required String documentId,
  }) async {
    return await collection(collectionPath).doc(documentId).get();
  }

  /// Get all documents in a collection
  Future<QuerySnapshot<Map<String, dynamic>>> getAll({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query = collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return await query.get();
  }

  /// Update a document
  Future<void> update({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await collection(collectionPath).doc(documentId).update(data);
  }

  /// Delete a document
  Future<void> delete({
    required String collectionPath,
    required String documentId,
  }) async {
    await collection(collectionPath).doc(documentId).delete();
  }

  /// Stream a single document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument({
    required String collectionPath,
    required String documentId,
  }) {
    return collection(collectionPath).doc(documentId).snapshots();
  }

  /// Stream all documents in a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// Get documents in a subcollection
  Future<QuerySnapshot<Map<String, dynamic>>> getSubcollection({
    required String parentCollection,
    required String parentId,
    required String subcollection,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query =
        collection(parentCollection).doc(parentId).collection(subcollection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return await query.get();
  }

  /// Stream documents in a subcollection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSubcollection({
    required String parentCollection,
    required String parentId,
    required String subcollection,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query =
        collection(parentCollection).doc(parentId).collection(subcollection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// Add a document to a subcollection
  Future<DocumentReference<Map<String, dynamic>>> addToSubcollection({
    required String parentCollection,
    required String parentId,
    required String subcollection,
    required Map<String, dynamic> data,
  }) async {
    return await collection(parentCollection)
        .doc(parentId)
        .collection(subcollection)
        .add(data);
  }

  /// Update a document in a subcollection
  Future<void> updateSubcollectionDoc({
    required String parentCollection,
    required String parentId,
    required String subcollection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await collection(parentCollection)
        .doc(parentId)
        .collection(subcollection)
        .doc(documentId)
        .update(data);
  }

  /// Delete a document from a subcollection
  Future<void> deleteFromSubcollection({
    required String parentCollection,
    required String parentId,
    required String subcollection,
    required String documentId,
  }) async {
    await collection(parentCollection)
        .doc(parentId)
        .collection(subcollection)
        .doc(documentId)
        .delete();
  }

  /// Run a batch write operation
  Future<void> runBatch(
    Future<void> Function(WriteBatch batch) operations,
  ) async {
    final batch = _firestore.batch();
    await operations(batch);
    await batch.commit();
  }

  /// Run a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) operations,
  ) async {
    return await _firestore.runTransaction(operations);
  }

  /// Get server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}

/// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
