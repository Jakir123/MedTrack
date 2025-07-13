import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_track/features/medicines/medicine_model.dart';
import 'package:med_track/features/medicines/medicine_viewmodel.dart';
import 'package:med_track/features/companies/company_viewmodel.dart';
import 'package:med_track/features/medicines/add_edit_medicine_sheet.dart';
import 'package:med_track/features/representatives/representative_viewmodel.dart';
import 'package:med_track/widgets/search_bar.dart' as custom;

// Simple loading widget
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// Simple empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class MedicineListScreen extends StatefulWidget {
  final String? userId;
  final bool isAnonymous;

  const MedicineListScreen({
    super.key,
    required this.userId,
    this.isAnonymous = false,
  });

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  List<DropdownMenuItem<String>> _buildRepresentativeDropdownItems(RepresentativeViewModel repVm) {
    if (_selectedCompanyId == null) {
      return [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select a company first'),
        ),
      ];
    }

    // Add a null check for representatives list
    if (repVm.representatives == null) {
      return [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Loading...'),
        ),
      ];
    }

    final repsForCompany = repVm.representatives!
        .where((rep) => rep.companyId == _selectedCompanyId)
        .toList();

    if (repsForCompany.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('No representatives found'),
        ),
      ];
    }

    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('All Representatives'),
      ),
      ...repsForCompany.map<DropdownMenuItem<String>>((rep) => DropdownMenuItem<String>(
            value: rep.id,
            child: Text(rep.name),
          )),
    ];
  }
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCompanyId;
  String? _selectedRepresentativeId;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      final viewModel = context.read<MedicineViewModel>();
      viewModel.initialize(widget.userId, isAnonymous: widget.isAnonymous);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilters() {
    final companyVm = context.read<CompanyViewModel>();
    final repVm = context.read<RepresentativeViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filter Medicines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCompanyId,
              decoration: const InputDecoration(
                labelText: 'Filter by Company',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Companies'),
                ),
                ...companyVm.companies.map((company) {
                  return DropdownMenuItem(
                    value: company.id,
                    child: Text(company.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() => _selectedCompanyId = value);
                context.read<MedicineViewModel>().setCompanyFilter(value);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCompanyId = null;
                  _selectedRepresentativeId = null;
                });
                context.read<MedicineViewModel>().clearFilters();
                Navigator.pop(context);
              },
              child: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditMedicine({Medicine? medicine}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditMedicineSheet(
        medicine: medicine,
        userId: widget.userId,
        isAnonymous: widget.isAnonymous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: custom.SearchBar(
              controller: _searchController,
              hintText: 'Search medicines...',
              onChanged: (value) {
                context.read<MedicineViewModel>().setSearchQuery(value);
              },
            ),
          ),
          Consumer<MedicineViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.isLoading) {
                return const Expanded(child: LoadingIndicator());
              }

              if (viewModel.error != null) {
                return Expanded(
                  child: Center(
                    child: Text(
                      'Error: ${viewModel.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                );
              }

              if (viewModel.medicines.isEmpty) {
                return Expanded(
                  child: EmptyState(
                    icon: Icons.medication,
                    title: 'No Medicines Found',
                    message: 'Add a new medicine to get started',
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: viewModel.medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = viewModel.medicines[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          medicine.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (medicine.companyName != null)
                              Text('Company: ${medicine.companyName}'),
                            if (medicine.representativeName != null)
                              Text('Rep: ${medicine.representativeName}'),
                            if (medicine.quantityInStock != null && medicine.quantityInStock! > 0)
                              Text('In Stock: ${medicine.quantityInStock}'),
                            if (medicine.quantityInStock == null || medicine.quantityInStock == 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditMedicine(medicine: medicine),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditMedicine(medicine: medicine),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditMedicine(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
