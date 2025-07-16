import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:med_track/features/medicines/medicine_model.dart';
import 'package:med_track/utils/firebase_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../medicine_list_screen.dart';

class OutOfStockMedicineViewModel extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _error;

  Future<void> toggleListening() async {
    if (_isListening && _speech.isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    } else {
      final isAvailable = await _speech.initialize();
      if (isAvailable) {
        await _speech.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            print("Listening: $_lastWords");
            notifyListeners();
          },
          listenFor: const Duration(seconds: 5),
          pauseFor: const Duration(seconds: 1),
          partialResults: true,
          localeId: 'en_US',
        );
        _isListening = true;
        notifyListeners();
      }
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> confirmVoiceInput(String? userId,String medicineName) async {
    try {
      if (userId == null) {
        throw Exception('User ID is required');
      }
      
      final snapshot = await _firebaseService.getAllMedicines(userId).first;
      final allMedicines = snapshot.docs.map((doc) => 
        Medicine.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      Medicine? medicine;
      try {
        medicine = allMedicines.firstWhere(
          (m) => m.name.toLowerCase() == medicineName.toLowerCase(),
        );
      } catch (e) {
        medicine = null;
      }

      if (medicine != null) {
        await updateMedicineQuantity(userId, medicine.id, 0);
      } else {
        _setError('Medicine not found: $medicineName');
      }
    } catch (e) {
      _setError('Failed to process voice input: $e');
    }
  }

  Future<void> updateMedicineQuantity(String? userId,String medicineId, int quantity) async {
    try {
      await _firebaseService.toggleMedicineStockStatus(
        userId: userId!,
        medicineId: medicineId,
        quantity: quantity,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  List<Medicine> _outOfStockMedicines = [];
  String? _searchQuery;
  DateTime? _timeRangeStart;
  DateTime? _timeRangeEnd;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Medicine> get outOfStockMedicines => _filteredMedicines;
  String? get searchQuery => _searchQuery;
  DateTime? get timeRangeStart => _timeRangeStart;
  DateTime? get timeRangeEnd => _timeRangeEnd;

  // Get filtered medicines based on search and filters
  List<Medicine> get _filteredMedicines {
    List<Medicine> result = _outOfStockMedicines;

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      result = result.where((m) {
        return m.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
               (m.companyName?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false) ||
               (m.representativeName?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply time range filter
    if (_timeRangeStart != null) {
      result = result.where((m) {
        final createdAt = m.updatedAt ?? DateTime.now();
        return createdAt.isAfter(_timeRangeStart!) || createdAt.isAtSameMomentAs(_timeRangeStart!);
      }).toList();
    }

    return result;
  }

  // Initialize the view model with user ID
  void initialize(String? userId, {bool isAnonymous = false}) {
    if (userId == null) return;
    
    _firebaseService
        .getOutOfStockMedicines(userId, isAnonymous: isAnonymous)
        .listen((snapshot) {
      _outOfStockMedicines = snapshot.docs
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

  void setTimeRangeFilter(DateTime? startDate) {
    _timeRangeStart = startDate;
    notifyListeners();
  }


  // Clear all filters
  void clearFilters() {
    _searchQuery = null;
    notifyListeners();
  }

  // Sort medicines by a specific field
  void sortMedicines(SortField field, bool isAscending) {
    _outOfStockMedicines.sort((a, b) {
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


  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }


  void reset() {
    _isLoading = false;
    _error = null;
    _searchQuery = null;
    _timeRangeStart = null;
    _timeRangeEnd = null;
    _outOfStockMedicines = []; // Clear the medicines list
    notifyListeners();
  }
}
