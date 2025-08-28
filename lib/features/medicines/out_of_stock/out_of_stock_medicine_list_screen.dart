import 'package:flutter/material.dart';
import 'package:med_track/features/medicines/add_edit_medicine_sheet.dart';
import 'package:med_track/features/medicines/medicine_model.dart';
import 'package:med_track/widgets/search_bar.dart' as custom;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../medicine_list_screen.dart';
import 'add_out_of_stock_medicine_sheet.dart';
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
    super.dispose();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddOutOfStockMedicineSheet(
        userId: widget.userId,
      ),
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
                    message: 'To add out of stock medicine, tap the + button',
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
                              Row(
                                children: [
                                  Text('Rep: ${medicine.representativeName}'),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.call, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final phone = await context
                                          .read<OutOfStockMedicineViewModel>()
                                          .getRepresentativePhone(
                                          widget.userId,
                                          medicine.representativeId
                                      );
                                      if (phone != null) {
                                        final url = 'tel:$phone';
                                        if (await canLaunchUrl(Uri.parse(url))) {
                                          await launchUrl(Uri.parse(url));
                                        }
                                      }else{
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Representative phone number not found')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
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
          _showManualAddSheet();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
