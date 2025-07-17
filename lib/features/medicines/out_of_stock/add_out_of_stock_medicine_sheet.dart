import 'package:flutter/material.dart';
import 'package:med_track/features/medicines/medicine_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../utils/toast_widget.dart';
import '../medicine_model.dart';
import 'out_of_stock_medicine_viewmodel.dart';

class AddOutOfStockMedicineSheet extends StatefulWidget {
  final String? userId;
  const AddOutOfStockMedicineSheet({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _AddOutOfStockMedicineSheetState createState() => _AddOutOfStockMedicineSheetState();
}

class _AddOutOfStockMedicineSheetState extends State<AddOutOfStockMedicineSheet> {
  late final TextEditingController _searchController;
  final List<Medicine> _medicineSuggestions = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  void _updateMedicineQuantity(Medicine medicine) async{
    if (medicine.quantityInStock == 0) {
      CustomToast.showErrorToast(
        'Medicine is already out of stock'
      );
      return;
    }
    await context.read<OutOfStockMedicineViewModel>().updateMedicineQuantity(
      widget.userId,
      medicine.id,
      0,
    );
    Navigator.pop(context);
  }

  Future<void> _toggleListening({bool shouldStop = false}) async {
    if (shouldStop) {
      _stopListening();
      return;
    }

    if (_isListening) {
      _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      // Request the permission
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<void> _startListening() async {
    _lastWords = '';
    if (!_isListening) {
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        CustomToast.showErrorToast('Microphone permission is required for voice input');
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            _stopListening();
          }
        },
        onError: (error) {
          _stopListening();
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                _searchController.text = _lastWords;
                _performSearch(_lastWords);
                _stopListening();
              }
            });
          },
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _medicineSuggestions.clear());
      return;
    }

    final medicineVM = context.read<MedicineViewModel>();
    setState(() {
      _medicineSuggestions.clear();
      _medicineSuggestions.addAll(
        medicineVM.medicines
            .where((medicine) =>
                medicine.name.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 38, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Marked a medicine out of stock',
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
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search medicine...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: _isListening ? Colors.red : null,
                          ),
                          onPressed: _toggleListening,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _performSearch,
                onTap: () {
                  if (_isListening) {
                    _toggleListening();
                  }
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
                      color: index.isEven ? Colors.grey[100] : Colors.grey[150],
                      child: ListTile(
                        title: Text(
                          '${suggestion.name} - ${suggestion.quantityInStock}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${suggestion.companyName}'),
                        onTap: () {
                          _searchController.text = suggestion.name;
                          _updateMedicineQuantity(suggestion);
                        },
                      ),
                    );
                  },
                ),
              ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Listening...\nSay the medicine name', style: TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    if (_lastWords.isNotEmpty)
                      Text('Recognized: $_lastWords'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _stopListening,
                      icon: const Icon(Icons.mic_off),
                      label: const Text('Stop Listening'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              )
            else if (_medicineSuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Search the medicine name \nOr speak the medicine name \nand click on the item to add it as out of stock",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),textAlign: TextAlign.center,),
              ),
          ],
        ),
      ),
    );
  }
}
