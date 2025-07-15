import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return result.user;
  }

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  // Sign up with email and password
  Future<User?> signUpV2(String email, String password) async {
    try {
      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      return userCredential.user;
    } catch (e) {
      // Rethrow the error to be handled by the UI layer
      rethrow;
    }
  }

// Sign in with email and password
  Future<User?> signInV2(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Sign out the user if email is not verified
        await signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before signing in.',
        );
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Invalid email or password.',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

// Add this helper method to check email verification status
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email address.',
        );
      }
      rethrow;
    }
  }

// Add this method to resend verification email
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw Exception('No unverified user found');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Change user password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in');

    // Re-authenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Company Operations

  // Add or update a company
  Future<DocumentReference> saveCompany(String userId, Map<String, dynamic> companyData, {String? companyId, bool isAnonymous = false}) async {
    final col = _getUserCollection(userId, 'companies', isAnonymous);
    if (companyId != null) {
      await col.doc(companyId).update(companyData);
      return col.doc(companyId);
    } else {
      return await col.add(companyData);
    }
  }

  // Delete a company
  Future<void> deleteCompany(String userId, String companyId, {bool isAnonymous = false}) async {
    final col = _getUserCollection(userId, 'companies', isAnonymous);
    await col.doc(companyId).delete();
  }

  // Get all companies for a user
  Stream<QuerySnapshot> getCompanies(String userId, {bool isAnonymous = false}) {
    final col = _getUserCollection(userId, 'companies', isAnonymous);
    return col.snapshots();
  }


  // Medicine Operations
  
  // Add or update a medicine with company and representative association
  Future<DocumentReference> saveMedicine({
    required String userId,
    required String companyId,
    required String representativeId,
    required Map<String, dynamic> medicineData,
    required int quantity,
    String? medicineId,
  }) async {
    if (quantity < 0) {
      throw ArgumentError('Quantity cannot be negative');
    }
    // First verify the representative belongs to the company
    final repDoc = await _getUserCollection(userId, 'representatives', false)
        .doc(representativeId)
        .get();
        
    if (!repDoc.exists || repDoc.data()?['companyId'] != companyId) {
      throw Exception('Representative does not belong to the specified company');
    }

    final col = _getUserCollection(userId, 'medicines', false);
    final now = FieldValue.serverTimestamp();
    final medicineDataWithRelations = {
      ...medicineData,
      'companyId': companyId,
      'representativeId': representativeId,
      'updatedAt': now,
    };

    if (medicineId != null) {
      await col.doc(medicineId).update(medicineDataWithRelations);
      return col.doc(medicineId);
    } else {
      // Create a new map for the new document
      final newMedicine = Map<String, dynamic>.from(medicineDataWithRelations)
        ..addAll({
          'createdAt': now,
        });
      
      // Set initial quantity and restock date if in stock
      if (medicineData['isFinished'] != true) {
        newMedicine['lastRestocked'] = now;
        newMedicine['quantity'] = quantity;
      } else {
        newMedicine['quantity'] = 0; // Out of stock
      }
      
      return await col.add(newMedicine);
    }
  }

  // Toggle the isFinished status of a medicine
  Future<void> toggleMedicineStockStatus({
    required String userId,
    required String medicineId,
    required bool isFinished,
    required int quantity,
  }) async {
    if (quantity < 0) {
      throw ArgumentError('Quantity cannot be negative');
    }
    
    final now = FieldValue.serverTimestamp();
    final updateData = <String, dynamic>{
      'isFinished': isFinished,
      'updatedAt': now,
      'quantity': isFinished ? 0 : quantity,
    };
    
    if (isFinished) {
      // Marking as out of stock - update stockedOutAt
      updateData['stockedOutAt'] = now;
    } else {
      // Marking as in-stock - update lastRestocked
      updateData['lastRestocked'] = now;
      // Clear the stockedOutAt since it's no longer out of stock
      updateData['stockedOutAt'] = FieldValue.delete();
    }
    
    await _getUserCollection(userId, 'medicines', false)
        .doc(medicineId)
        .update(updateData);
  }

  // Delete a medicine
  Future<void> deleteMedicine(String userId, String medicineId) async {
    final col = _getUserCollection(userId, 'medicines', false);
    await col.doc(medicineId).delete();
    
    // Note: In a real app, you might want to handle any cleanup or
    // cascading deletes here if needed
  }

  // Get all medicines for a company
  Stream<QuerySnapshot> getMedicinesByCompany(String userId, String companyId) {
    final col = _getUserCollection(userId, 'medicines', false);
    return col
        .where('companyId', isEqualTo: companyId)
        .orderBy('name')
        .snapshots();
  }

  // Get all medicines for a user
  Stream<QuerySnapshot> getAllMedicines(String userId, {bool isAnonymous = false}) {
    return _getUserCollection(userId, 'medicines', isAnonymous)
        .orderBy('name')
        .snapshots();
  }
  
  // Get all in-stock medicines (isFinished == false)
  Stream<QuerySnapshot> getInStockMedicines(String userId, {bool isAnonymous = false}) {
    return _getUserCollection(userId, 'medicines', isAnonymous)
        .where('quantityInStock', isEqualTo: 0)
        .orderBy('name')
        .snapshots();
  }
  
  // Get all out-of-stock medicines (isFinished == true)
  Stream<QuerySnapshot> getOutOfStockMedicines(String userId, {bool isAnonymous = false}) {
    return _getUserCollection(userId, 'medicines', isAnonymous)
        .where('quantityInStock', isEqualTo: 0)
        .snapshots();
  }

  // Get medicines for a specific representative
  Stream<QuerySnapshot> getMedicinesByRepresentative(String userId, String representativeId) {
    final col = _getUserCollection(userId, 'medicines', false);
    return col
        .where('representativeId', isEqualTo: representativeId)
        .orderBy('name')
        .snapshots();
  }

  // Representative Operations
  
  // Add or update a representative
  Future<DocumentReference> saveRepresentative({
    required String userId,
    required String companyId,
    required Map<String, dynamic> repData,
    String? repId,
  }) async {
    // Verify company exists
    final companyDoc = await _getUserCollection(userId, 'companies', false)
        .doc(companyId)
        .get();
        
    if (!companyDoc.exists) {
      throw Exception('Company not found');
    }

    final col = _getUserCollection(userId, 'representatives', false);
    final repDataWithCompany = {
      ...repData,
      'companyId': companyId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (repId != null) {
      await col.doc(repId).update(repDataWithCompany);
      return col.doc(repId);
    } else {
      return await col.add({
        ...repDataWithCompany,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Delete a representative
  Future<void> deleteRepresentative(String userId, String repId) async {
    final repRef = _getUserCollection(userId, 'representatives', false).doc(repId);
    
    // Check if any medicines are assigned to this representative
    final medicines = await _getUserCollection(userId, 'medicines', false)
        .where('representativeId', isEqualTo: repId)
        .limit(1)
        .get();
        
    if (medicines.docs.isNotEmpty) {
      throw Exception('Cannot delete representative with assigned medicines');
    }
    
    await repRef.delete();
  }

  // Get all representatives for a company
  Stream<QuerySnapshot> getRepresentativesByCompany(String userId, String companyId) {
    final col = _getUserCollection(userId, 'representatives', false);
    return col
        .where('companyId', isEqualTo: companyId)
        .orderBy('name')
        .snapshots();
  }
  
  // Get a single representative by ID
  Future<DocumentSnapshot> getRepresentative(String userId, String repId) async {
    return await _getUserCollection(userId, 'representatives', false)
        .doc(repId)
        .get();
  }
  Stream<QuerySnapshot> getAllRepresentatives(String userId, {bool isAnonymous = false}) {
    return _getUserCollection(userId, 'representatives', isAnonymous)
        .orderBy('name')
        .snapshots();
  }

  // Helper method to get the appropriate collection reference
  CollectionReference<Map<String, dynamic>> _getUserCollection(String userId, String collectionName, bool isAnonymous) {
    return isAnonymous
        ? _firestore.collection('anonymous').doc(userId).collection(collectionName)
        : _firestore.collection('users').doc(userId).collection(collectionName);
  }


  Future<void> updateTodoReminderStatus({
    required String userId,
    required String docId,
    required bool reminder,
    required bool isAnonymous,
  }) async {
    final ref = isAnonymous
        ? _firestore.collection('anonymous').doc(userId).collection('todos').doc(docId)
        : _firestore.collection('users').doc(userId).collection('todos').doc(docId);
    await ref.update({'reminder': reminder});
  }


}
