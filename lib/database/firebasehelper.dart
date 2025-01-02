import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/task.dart';

class FirestoreHelper {
  static final FirestoreHelper _instance = FirestoreHelper._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreHelper._internal();

  factory FirestoreHelper() {
    return _instance;
  }

  Future<DocumentReference> addDocument(
      String userId, CardItem cardItem) async {
    try {
      return await _firestore
          .collection("Users")
          .doc(userId)
          .collection("Tasks")
          .add(cardItem.toFirestoreMap());
    } catch (e) {
      throw Exception("Error adding document: $e");
    }
  }

  Future<String?> getDocumentIdByField(String userId, int fieldId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .collection("Tasks")
          .where("id", isEqualTo: fieldId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      } else {
        print("No document found with id: $fieldId");
        return null;
      }
    } catch (e) {
      print("Error retrieving document ID: $e");
      return null;
    }
  }

  Future<void> updateDocument(
      String userId, String documentId, CardItem cardItem) async {
    try {
      await _firestore
          .collection("Users")
          .doc(userId)
          .collection("Tasks")
          .doc(documentId)
          .update(cardItem.toFirestoreMap());
    } catch (e) {
      throw Exception("Error updating document: $e");
    }
  }

  Future<void> deleteDocument(String userId, String documentId) async {
    try {
      await _firestore
          .collection("Users")
          .doc(userId)
          .collection("Tasks")
          .doc(documentId)
          .delete();
    } catch (e) {
      throw Exception("Error deleting document: $e");
    }
  }

  Future<List<CardItem>> getCardItems(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("Users")
          .doc(userId)
          .collection("Tasks")
          .get();

      return snapshot.docs.map((doc) {
        return CardItem.fromFirestoreMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Error retrieving CardItems: $e");
    }
  }

  Future<DocumentSnapshot> getDocument(
      String collection, String documentId) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      throw Exception("Error retrieving document: $e");
    }
  }
}
