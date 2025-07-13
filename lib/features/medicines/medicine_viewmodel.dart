import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:med_track/features/medicines/medicine_model.dart';
import 'package:med_track/utils/firebase_service.dart';

import 'medicine_list_screen.dart';

class MedicineViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _error;
  List<Medicine> _medicines = [];
  String? _searchQuery;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Medicine> get medicines => _filteredMedicines;
  String? get searchQuery => _searchQuery;

  // Get filtered medicines based on search and filters
  List<Medicine> get _filteredMedicines {
    var result = List<Medicine>.from(_medicines);

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      result = result.where((medicine) {
        return medicine.name.toLowerCase().contains(query) ||
            (medicine.companyName?.toLowerCase().contains(query) ?? false) ||
            (medicine.representativeName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
  }

  // Initialize the view model with user ID
  void initialize(String? userId, {bool isAnonymous = false}) {
    if (userId == null) return;
    
    _firebaseService
        .getAllMedicines(userId, isAnonymous: isAnonymous)
        .listen((snapshot) {
      _medicines = snapshot.docs
          .map((doc) => Medicine.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    }, onError: (error) {
      _setError('Failed to load medicines: $error');
    });
  }

  // Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }


  // Clear all filters
  void clearFilters() {
    _searchQuery = null;
    notifyListeners();
  }

  // Sort medicines by a specific field
  void sortMedicines(SortField field, bool isAscending) {
    _medicines.sort((a, b) {
      switch (field) {
        case SortField.name:
          return isAscending 
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        case SortField.quantity:
          final aStock = a.quantityInStock ?? 0;
          final bStock = b.quantityInStock ?? 0;
          return isAscending 
              ? aStock.compareTo(bStock)
              : bStock.compareTo(aStock);
      }
      return 0;
    });
    notifyListeners();
  }

  // Add a new medicine
  Future<void> addMedicine(Medicine medicine, String? userId, {bool isAnonymous = false}) async {
    if (userId == null) {
      throw Exception('User must be logged in to add a medicine');
    }
    if (medicine.companyId == null || medicine.representativeId == null) {
      throw Exception('Medicine must have company and representative IDs');
    }

    try {
      _setLoading(true);
      await _firebaseService.saveMedicine(
        userId: userId,
        companyId: medicine.companyId!,
        representativeId: medicine.representativeId!,
        medicineData: medicine.toMap(),
        quantity: medicine.quantityInStock ?? 0,
      );
    } catch (e) {
      _setError('Failed to add medicine: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing medicine
  Future<void> updateMedicine(Medicine medicine, String? userId, {bool isAnonymous = false}) async {
    if (userId == null) {
      throw Exception('User must be logged in to update a medicine');
    }
    if (medicine.id == null || medicine.companyId == null || medicine.representativeId == null) {
      throw Exception('Medicine must have ID, company ID, and representative ID');
    }

    try {
      _setLoading(true);
      await _firebaseService.saveMedicine(
        userId: userId,
        companyId: medicine.companyId!,
        representativeId: medicine.representativeId!,
        medicineData: medicine.toMap(),
        quantity: medicine.quantityInStock ?? 0,
        medicineId: medicine.id,
      );
    } catch (e) {
      _setError('Failed to update medicine: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a medicine
  Future<void> deleteMedicine(String medicineId, String? userId, {bool isAnonymous = false}) async {
    if (userId == null) {
      throw Exception('User must be logged in to delete a medicine');
    }

    try {
      _setLoading(true);
      await _firebaseService.deleteMedicine(userId, medicineId);
    } catch (e) {
      _setError('Failed to delete medicine: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }
}
