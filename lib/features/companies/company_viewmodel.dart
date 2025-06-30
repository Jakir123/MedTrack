import 'package:flutter/material.dart';
import 'package:med_track/features/companies/company_model.dart';
import 'package:med_track/utils/firebase_service.dart';

class CompanyViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _error;

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all companies for the current user
  Future<void> fetchCompanies(String userId, {bool isAnonymous = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firebaseService.getCompanies(userId, isAnonymous: isAnonymous).first;
      _companies = snapshot.docs
          .map((doc) => Company.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load companies: ${e.toString()}';
      _companies = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream of companies for real-time updates
  Stream<List<Company>> streamCompanies(String userId, {bool isAnonymous = false}) {
    return _firebaseService
        .getCompanies(userId, isAnonymous: isAnonymous)
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Company.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Add a new company
  Future<void> addCompany(
      String userId, Map<String, dynamic> companyData) async {
    try {
      await _firebaseService.saveCompany(userId, companyData);
      await fetchCompanies(userId);
    } catch (e) {
      _error = 'Failed to add company: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Update an existing company
  Future<void> updateCompany(
      String userId, String companyId, Map<String, dynamic> companyData) async {
    try {
      await _firebaseService.saveCompany(userId, companyData, companyId: companyId);
      await fetchCompanies(userId);
    } catch (e) {
      _error = 'Failed to update company: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Delete a company
  Future<void> deleteCompany(String userId, String companyId) async {
    try {
      await _firebaseService.deleteCompany(userId, companyId);
      _companies.removeWhere((company) => company.id == companyId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete company: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
