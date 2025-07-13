import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_track/features/medicines/medicine_model.dart';
import 'package:med_track/features/medicines/medicine_viewmodel.dart';
import 'package:med_track/features/companies/company_viewmodel.dart';
import 'package:med_track/features/representatives/representative_viewmodel.dart';
import 'package:med_track/widgets/custom_text_form_field.dart';

class AddEditMedicineSheet extends StatefulWidget {
  final Medicine? medicine;
  final String? userId;
  final bool isAnonymous;

  const AddEditMedicineSheet({
    super.key,
    this.medicine,
    this.userId,
    this.isAnonymous = false,
  });

  @override

  State<AddEditMedicineSheet> createState() => _AddEditMedicineSheetState();
}

class _AddEditMedicineSheetState extends State<AddEditMedicineSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  String? _selectedCompanyId;
  String? _selectedRepresentativeId;
  bool _isLoading = false;
  bool _isDataLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.medicine?.quantityInStock == 0 ? '' : widget.medicine?.quantityInStock?.toString() ?? '',
    );
    _selectedCompanyId = widget.medicine?.companyId;
    _selectedRepresentativeId = widget.medicine?.representativeId;
    
    // Schedule data loading after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    setState(() => _isDataLoading = true);
    
    try {
      final companyVm = context.read<CompanyViewModel>();
      final repVm = context.read<RepresentativeViewModel>();
      
      // Load companies
      await companyVm.fetchCompanies(widget.userId ?? '', isAnonymous: widget.isAnonymous);
      
      // Load representatives
      await repVm.fetchRepresentatives(widget.userId ?? '', isAnonymous: widget.isAnonymous);
      
      // Update selected values if they exist
      if (widget.medicine?.companyId != null) {
        _selectedCompanyId = widget.medicine!.companyId;
      }
      if (widget.medicine?.representativeId != null) {
        _selectedRepresentativeId = widget.medicine!.representativeId;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDataLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final viewModel = context.read<MedicineViewModel>();
      final companyVm = context.read<CompanyViewModel>();
      final repVm = context.read<RepresentativeViewModel>();

      final company = companyVm.companies.firstWhere(
        (c) => c.id == _selectedCompanyId,
        orElse: () => throw Exception('Selected company not found'),
      );

      String? repName;
      if (_selectedRepresentativeId != null) {
        final rep = repVm.representatives.firstWhere(
          (r) => r.id == _selectedRepresentativeId,
          orElse: () => throw Exception('Selected representative not found'),
        );
        repName = rep.name;
      }

      final medicine = Medicine(
        id: widget.medicine?.id ?? '',
        name: _nameController.text.trim(),
        companyId: _selectedCompanyId!,
        companyName: company.name,
        representativeId: _selectedRepresentativeId,
        representativeName: repName,
        quantityInStock: _quantityController.text.trim().isNotEmpty
            ? int.tryParse(_quantityController.text.trim())
            : null,
      );

      if (widget.medicine == null) {
        await viewModel.addMedicine(
          medicine,
          widget.userId,
          isAnonymous: widget.isAnonymous,
        );
      } else {
        await viewModel.updateMedicine(
          medicine,
          widget.userId,
          isAnonymous: widget.isAnonymous,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save medicine: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyVm = context.read<CompanyViewModel>();
    final repVm = context.read<RepresentativeViewModel>();
    
    if (_isDataLoading || companyVm.isLoading || repVm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (companyVm.error != null || repVm.error != null) {
      print('companyVm.error: ${companyVm.error}');
      print('repVm.error: ${repVm.error}');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load data. Please try again.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final isEditing = widget.medicine != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Medicine' : 'Add New Medicine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _nameController,
                labelText: 'Medicine Name *',
                hintText: 'Enter medicine name',
                prefixIcon: const Icon(Icons.medication),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a medicine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCompanyId,
                decoration: const InputDecoration(
                  labelText: 'Company *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                items: companyVm.companies.map((company) {
                  return DropdownMenuItem(
                    value: company.id,
                    child: Text(company.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCompanyId = value;
                    _selectedRepresentativeId = null; // Reset rep when company changes
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a company';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRepresentativeId,
                decoration: const InputDecoration(
                  labelText: 'Representative *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: [
                  ...repVm.representatives
                      .where((rep) => rep.companyId == _selectedCompanyId)
                      .map((rep) {
                    return DropdownMenuItem(
                      value: rep.id,
                      child: Text(rep.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRepresentativeId = value;
                  });
                },
                validator: (value) {
                if (value == null) {
                  return 'Please select representative';
                }
                return null;
              },
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _quantityController,
                labelText: 'Quantity in Stock (Optional)',
                hintText: 'Enter quantity',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.numbers),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMedicine,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Medicine' : 'Add Medicine'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
