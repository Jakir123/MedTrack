import 'dart:async';
import 'package:flutter/material.dart';
import 'package:med_track/features/representatives/representative_model.dart';
import 'package:med_track/utils/firebase_service.dart';

class RepresentativeViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Initialize with user ID
  void initialize(String userId) {
    _currentUserId = userId;
  }

  // Stream of representatives for the current user
  Stream<List<Representative>> streamRepresentatives() {
    if (_currentUserId == null) {
      return Stream.empty();
    }
    
    return _firebaseService
        .getAllRepresentatives(_currentUserId!)
        .map((snapshot) => snapshot.docs
            .map((doc) => 
                Representative.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList())
        .handleError((error) {
          _setError('Error loading representatives: $error');
          return [];
        });
  }

  // Add a new representative
  Future<void> addRepresentative({
    required String companyId,
    required Map<String, dynamic> repData,
  }) async {
    if (_currentUserId == null) {
      throw Exception('ViewModel not initialized. Call initialize() first.');
    }
    
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.saveRepresentative(
        userId: _currentUserId!,
        companyId: companyId,
        repData: repData,
      );
      
    } catch (e) {
      _setError('Failed to add representative: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing representative
  Future<void> updateRepresentative({
    required String companyId,
    required String repId,
    required Map<String, dynamic> repData,
  }) async {
    if (_currentUserId == null) {
      throw Exception('ViewModel not initialized. Call initialize() first.');
    }
    
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.saveRepresentative(
        userId: _currentUserId!,
        companyId: companyId,
        repData: repData,
        repId: repId,
      );
      
    } catch (e) {
      _setError('Failed to update representative: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a representative
  Future<void> deleteRepresentative(String repId) async {
    if (_currentUserId == null) {
      throw Exception('ViewModel not initialized. Call initialize() first.');
    }
    
    try {
      _setLoading(true);
      _setError(null);
      
      await _firebaseService.deleteRepresentative(_currentUserId!, repId);
      
    } catch (e) {
      _setError('Failed to delete representative: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get a single representative by ID
  Future<Representative?> getRepresentative(String userId, String repId) async {
    try {
      final doc = await _firebaseService.getRepresentative(userId, repId);
      if (doc.exists) {
        return Representative.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      _setError('Failed to get representative: $e');
      return null;
    }
  }
}
