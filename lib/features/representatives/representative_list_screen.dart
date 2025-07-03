import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:med_track/features/companies/company_model.dart';
import 'package:med_track/features/companies/company_viewmodel.dart';
import 'package:med_track/features/representatives/representative_model.dart';
import 'package:med_track/features/representatives/representative_viewmodel.dart';
import 'package:med_track/utils/firebase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RepresentativeListScreen extends StatefulWidget {
  final bool isAnonymous;

  const RepresentativeListScreen({
    super.key,
    this.isAnonymous = false,
  });

  @override
  State<RepresentativeListScreen> createState() => _RepresentativeListScreenState();
}

class _RepresentativeListScreenState extends State<RepresentativeListScreen> {
  late final RepresentativeViewModel _viewModel;
  final FirebaseService _firebaseService = FirebaseService();
  String? _userId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _editingRepId;
  String? _selectedCompanyId;
  List<Company> _companies = [];
  Representative? _editingRep;

  @override
  void initState() {
    super.initState();
    _userId = widget.isAnonymous ? null : _firebaseService.getCurrentUser()?.uid;
    // Initialize the ViewModel with user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<RepresentativeViewModel>();
      viewModel.initialize(_userId!);
      _loadCompanies();
    });
  }

  Future<void> _loadCompanies() async {
    final companyViewModel = context.read<CompanyViewModel>();
    await companyViewModel.fetchCompanies(_userId!);
    if (mounted) {
      setState(() {
        _companies = companyViewModel.companies;
        if (_companies.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = _companies.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showAddEditRepresentativeDialog([Representative? representative]) {
    if (representative != null) {
      _editingRep = representative;
      _editingRepId = representative.id;
      _nameController.text = representative.name;
      _emailController.text = representative.email ?? '';
      _phoneController.text = representative.phone;
      _addressController.text = representative.address ?? '';
      _selectedCompanyId = representative.companyId;
    } else {
      _editingRep = null;
      _editingRepId = null;
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _selectedCompanyId = _companies.isNotEmpty ? _companies.first.id : null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingRep == null ? 'Add Representative' : 'Edit Representative',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
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
                  ),
                  items: _companies.map((company) {
                    return DropdownMenuItem(
                      value: company.id,
                      child: Text(company.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCompanyId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a company';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addOrUpdateRepresentative,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addOrUpdateRepresentative() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<RepresentativeViewModel>();
    final repData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
    };

    try {
      if (_editingRep == null) {
        await viewModel.addRepresentative(
          companyId: _selectedCompanyId!,
          repData: repData,
        );
      } else {
        await viewModel.updateRepresentative(
          companyId: _selectedCompanyId!,
          repId: _editingRep!.id,
          repData: repData,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteRepresentative(Representative representative) async {
    final viewModel = context.read<RepresentativeViewModel>();
    try {
      await viewModel.deleteRepresentative(representative.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Representative deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting representative: $e')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Representative representative) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delete Representative',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete ${representative.name}?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _deleteRepresentative(representative);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRepresentativeCard(Representative representative) {
    final company = _companies.firstWhere(
          (c) => c.id == representative.companyId,
      orElse: () => Company(id: '', name: 'Unknown Company'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            representative.name.isNotEmpty ? representative.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          representative.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company.name),
            if (representative.phone.isNotEmpty)
              GestureDetector(
                onTap: () => _makePhoneCall('tel:${representative.phone}'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      representative.phone,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditRepresentativeDialog(representative);
            } else if (value == 'delete') {
              _showDeleteConfirmation(representative);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: () {
          _showAddEditRepresentativeDialog(representative);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RepresentativeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading representatives',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.initialize(_userId!);
                      _loadCompanies();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Representative>>(
            stream: viewModel.streamRepresentatives(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
                );
              }

              final representatives = snapshot.data ?? [];

              if (representatives.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No representatives found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a new representative to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: representatives.length,
                itemBuilder: (context, index) {
                  return _buildRepresentativeCard(representatives[index]);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditRepresentativeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
