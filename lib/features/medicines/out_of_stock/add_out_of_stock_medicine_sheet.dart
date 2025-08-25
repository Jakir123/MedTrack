import 'dart:async';

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
  final List<Medicine> _allMedicines = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadMedicineList();
    _initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicineList() async {
    final medicineVM = context.read<MedicineViewModel>();
    final medicines = await medicineVM.getAllInStockMedicines(widget.userId);
    _allMedicines.clear();
    _allMedicines.addAll(medicines);
    _performSearch(_searchController.text);
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
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
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _stopListening();
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          _stopListening();
        },
      );

      if (available) {
        setState(() => _isListening = true);
        DateTime lastSpokeTime = DateTime.now();
        await _speech.listen(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          localeId: 'en_US',
          onResult: (result) {
            debugPrint('Speech Result: $result');
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                _searchController.text = _lastWords;
                _performSearch(_lastWords);
                _isListening = false;
              }
            });
          },
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          onDevice: false,
          onSoundLevelChange: (level) {
            // Optional: You can use this to show visual feedback of sound level
          },
        );

        // This runs after listening stops (even if nothing was said)
        // if (_isListening) {
        //   setState(() => _isListening = false);
        // }

        // Timer to handle "silence timeout"
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (!_isListening) {
            timer.cancel();
            return;
          }

          if (DateTime.now().difference(lastSpokeTime) >
              const Duration(seconds: 5)) { // same as pauseFor
            _stopListening();
            timer.cancel();
          }
        });

      }
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState((){
        _medicineSuggestions.clear();
        _medicineSuggestions.addAll(_allMedicines);
      });
      return;
    }
    setState(() {
      _medicineSuggestions.clear();
      _medicineSuggestions.addAll(
        _allMedicines
            .where((medicine) =>
                medicine.name.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    });
  }

  void _toggleStockOut(Medicine medicine) async {
    // First, update the local state to show the switch transition
    setState(() {
      // Create a copy with quantityInStock set to 0 to trigger the switch animation
      final updatedMedicine = medicine.copyWith(quantityInStock: 0);
      final index = _medicineSuggestions.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _medicineSuggestions[index] = updatedMedicine;
      }
    });

    // Then perform the actual update
    final viewModel = context.read<MedicineViewModel>();
    await viewModel.updateMedicine(
      medicine.copyWith(quantityInStock: 0),
      widget.userId,
      isAnonymous: false,
    );

    // Finally, remove the item after a short delay to show the transition
    await Future.delayed(const Duration(milliseconds: 300)); // Adjust timing as needed

    if (mounted) {
      setState(() {
        _medicineSuggestions.removeWhere((m) => m.id == medicine.id);
        _allMedicines.removeWhere((m) => m.id == medicine.id);
      });
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 0.0),
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
            Padding(
              padding: const EdgeInsets.only(left: 24.0,bottom: 8.0),
              child: Text(
                'Type or say the medicine name',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_medicineSuggestions.isNotEmpty && !_isListening)
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
                        trailing: Switch(
                          value: suggestion.quantityInStock == 0,
                          onChanged: (value) => _toggleStockOut(suggestion),
                          activeColor: Colors.red,
                          inactiveThumbColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
                          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                ),
              )
            else if (_medicineSuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "No medicines found\n",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextSpan(
                          text: "Type or Speak the medicine name correctly",
                          style: TextStyle(fontSize: 14), // Smaller font size
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ),
          ],
        ),
      ),
    );
  }
}
