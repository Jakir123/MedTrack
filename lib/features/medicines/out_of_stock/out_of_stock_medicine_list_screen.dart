import 'package:flutter/material.dart';
import 'package:med_track/features/medicines/add_edit_medicine_sheet.dart';
import 'package:med_track/features/medicines/medicine_model.dart';
import 'package:med_track/features/medicines/medicine_viewmodel.dart';
import 'package:med_track/widgets/search_bar.dart' as custom;
import 'package:provider/provider.dart';

import '../medicine_list_screen.dart';
import 'out_of_stock_medicine_viewmodel.dart';


class OutOfStockMedicineListScreen extends StatefulWidget {
  final String? userId;
  final bool isAnonymous;

  const OutOfStockMedicineListScreen({
    super.key,
    required this.userId,
    this.isAnonymous = false,
  });

  @override
  State<OutOfStockMedicineListScreen> createState() => _OutOfStockMedicineListScreenState();
}

class _OutOfStockMedicineListScreenState extends State<OutOfStockMedicineListScreen> {
  final Map<String, int> _originalQuantities = {};
  final TextEditingController _manualSearchController = TextEditingController();

  void _hideKeyboard(){
    // Hide keyboard and clear focus
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _toggleStockOut(Medicine medicine) async {
    final viewModel = context.read<OutOfStockMedicineViewModel>();
    
    if (medicine.quantityInStock == 0) {
      // If currently out of stock, restore original quantity
      final originalQuantity = _originalQuantities[medicine.id];
      if (originalQuantity != null) {
        await viewModel.updateMedicine(
          medicine.copyWith(quantityInStock: originalQuantity),
          widget.userId,
          isAnonymous: widget.isAnonymous,
        );
        _originalQuantities.remove(medicine.id);
      }
    } else {
      // If in stock, mark as out of stock and store original quantity
      _originalQuantities[medicine.id] = medicine.quantityInStock!;
      await viewModel.updateMedicine(
        medicine.copyWith(quantityInStock: 0),
        widget.userId,
        isAnonymous: widget.isAnonymous,
      );
    }
  }

  final TextEditingController _searchController = TextEditingController();

  SortField? _sortField;
  bool _isAscending = true;
  TimeRange? _selectedTimeRange = TimeRange.all;

  void _applyTimeRangeFilter(TimeRange range) {
    final now = DateTime.now();
    DateTime? startDate;
    
    switch (range) {
      case TimeRange.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case TimeRange.last7Days:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.last15Days:
        startDate = now.subtract(const Duration(days: 15));
        break;
      case TimeRange.lastMonth:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.last6Months:
        startDate = now.subtract(const Duration(days: 180));
        break;
      case TimeRange.thisYear:
        startDate = DateTime(now.year, 1, 1);
        break;
      case TimeRange.all:
        startDate = null;
        break;
    }

    context.read<OutOfStockMedicineViewModel>().setTimeRangeFilter(startDate);
  }

  void _toggleSort(SortField field) {
    if (_sortField == field) {
      _isAscending = !_isAscending;
    } else {
      _sortField = field;
      _isAscending = true;
    }
    _hideKeyboard();
    setState(() {});
    context.read<OutOfStockMedicineViewModel>().sortMedicines(field, _isAscending);
  }

  @override
  void initState() {
    super.initState();
    // Reset the ViewModel when the screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<OutOfStockMedicineViewModel>();
      viewModel.reset();
      if (widget.userId != null) {
        viewModel.initialize(widget.userId, isAnonymous: widget.isAnonymous);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualSearchController.dispose();
    super.dispose();
  }

  void _listenMedicineName() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer<OutOfStockMedicineViewModel>(
        builder: (context, viewModel, _) => StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: viewModel.isListening
                        ? const Icon(
                            Icons.mic,
                            size: 64,
                            color: Colors.red,
                          )
                        : const Icon(
                            Icons.mic_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (viewModel.lastWords.isNotEmpty)
                  Text(
                    viewModel.lastWords,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: viewModel.isListening ? null : () {
                        viewModel.toggleListening();
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Listening'),
                    ),
                    if (viewModel.lastWords.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Medicine'),
                              content: Text('Did you say "${viewModel.lastWords}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed ?? false) {
                            viewModel.confirmVoiceInput(widget.userId, viewModel.lastWords);
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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

  void _showManualAddSheet() {
    List<Medicine> _medicineSuggestions = [];
    _manualSearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height-40,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Handle keyboard dismiss
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Container(
                      color: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Out of Stock Medicine',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 8.0),
                    child: TextField(
                      controller: _manualSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search medicine...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _manualSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _manualSearchController.clear();
                                  setState(() {
                                    _medicineSuggestions = [];
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _medicineSuggestions = [];
                          });
                          return;
                        }

                        // Get suggestions from all medicines
                        final viewModel = context.read<MedicineViewModel>();
                        setState(() {
                          _medicineSuggestions = viewModel.medicines
                              .where((medicine) => medicine.name
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                          .where((medicine) => medicine.quantityInStock != 0)
                              .toList();
                        });
                      },
                    ),
                  ),
                  if (_medicineSuggestions.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _medicineSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _medicineSuggestions[index];
                          return Container(
                            color: index.isEven ? Colors.grey[100] : Colors.grey[200],
                            child: ListTile(
                              title: Text(
                                '${suggestion.name} - ${suggestion.quantityInStock}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${suggestion.companyName}'),
                              onTap: () {
                                _manualSearchController.text = suggestion.name;
                                final viewModel = context.read<MedicineViewModel>();
                                Medicine? medicine;
                                try {
                                  medicine = viewModel.medicines
                                      .firstWhere((m) => m.name == suggestion.name);
                                } catch (e) {
                                  medicine = null;
                                }
                                if (medicine != null) {
                                  _updateMedicineQuantity(medicine);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  if (_medicineSuggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Search the medicine name and click on the item to add it as out of stock'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateMedicineQuantity(Medicine medicine) {
    context.read<OutOfStockMedicineViewModel>().updateMedicineQuantity(
      widget.userId,
      medicine.id,
      0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: custom.SearchBar(
                        controller: _searchController,
                        hintText: 'Search medicines...',
                        onChanged: (value) {
                          context.read<OutOfStockMedicineViewModel>().setSearchQuery(value);
                        },
                      ),
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.filter_list),
                    //   onPressed: () {
                    //     _hideKeyboard();
                    //     showMenu<SortField>(
                    //       context: context,
                    //       position: RelativeRect.fromLTRB(
                    //         MediaQuery.of(context).size.width - 56,
                    //         128,
                    //         MediaQuery.of(context).size.width,
                    //         192,
                    //       ),
                    //       items: SortField.values.map((field) {
                    //         return PopupMenuItem<SortField>(
                    //           value: field,
                    //           child: Row(
                    //               children: [
                    //                 Icon(
                    //                   field == SortField.name
                    //                       ? Icons.sort_by_alpha
                    //                       : Icons.sort,
                    //                   color: field == _sortField
                    //                       ? Theme.of(context).colorScheme.primary
                    //                       : Theme.of(context).colorScheme.onSurface,
                    //                 ),
                    //                 const SizedBox(width: 8),
                    //                 Text(
                    //                   field.displayName,
                    //                   style: TextStyle(
                    //                     color: field == _sortField
                    //                         ? Theme.of(context).colorScheme.primary
                    //                         : Theme.of(context).colorScheme.onSurface,
                    //                   ),
                    //                 ),
                    //               ],
                    //           ),
                    //         );
                    //       }).toList(),
                    //     ).then((value) {
                    //       if (value != null) {
                    //         _toggleSort(value);
                    //       }
                    //     });
                    //   },
                    //   tooltip: 'Sort Options',
                    // ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TimeRange.values.map((range) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          label: Text(range.displayName),
                          selected: _selectedTimeRange == range,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTimeRange = range;
                              });
                              _applyTimeRangeFilter(range);
                            }
                          },
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: _selectedTimeRange == range 
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Consumer<OutOfStockMedicineViewModel>(
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

              if (viewModel.outOfStockMedicines.isEmpty) {
                return Expanded(
                  child: EmptyState(
                    icon: Icons.medication,
                    title: 'No Out of Stock Medicines Found',
                    message: 'Add a new medicine to get started',
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: viewModel.outOfStockMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = viewModel.outOfStockMedicines[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                medicine.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditMedicine(medicine: medicine),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (medicine.companyName != null)
                              Text('Company: ${medicine.companyName}'),
                            if (medicine.representativeName != null)
                              Text('Rep: ${medicine.representativeName}'),
                            SizedBox(height: 8),
                            if (medicine.quantityInStock != null && medicine.quantityInStock! > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'In Stock: ${medicine.quantityInStock}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: medicine.quantityInStock == 0,
                                    onChanged: (value) => _toggleStockOut(medicine),
                                    activeColor: Colors.red,
                                    inactiveThumbColor: Theme.of(context).primaryColor,
                                    inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
                                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                  ),
                                ],
                              ),
                            if (medicine.quantityInStock == null || medicine.quantityInStock == 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
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
                                  // Switch(
                                  //   value: medicine.quantityInStock == 0,
                                  //   onChanged: (value) => _toggleStockOut(medicine),
                                  //   activeColor: Colors.red,
                                  //   inactiveThumbColor: Theme.of(context).primaryColor,
                                  //   inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
                                  //   trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                  // ),
                                ],
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
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.keyboard),
                  title: const Text('Add Manually'),
                  onTap: () {
                    Navigator.pop(context);
                    _showManualAddSheet();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: const Text('Voice Input'),
                  onTap: () {
                    Navigator.pop(context);
                    _listenMedicineName();
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
