import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/memory.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  File? _imageFile;
  int _lockDays = 0; // 0 means unlocked
  bool _isSaving = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveMemory() async {
    final title = _titleController.text.trim();
    final date = _selectedDate;
    if (title.isEmpty || date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both a title and a date.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final box = Hive.box<Memory>('memoriesBox');
    DateTime? lockedUntil;
    if (_lockDays > 0) {
      lockedUntil = DateTime.now().add(Duration(days: _lockDays));
    }

    await box.add(Memory(
      title: title,
      date: date,
      imagePath: _imageFile?.path,
      lockedUntil: lockedUntil,
    ));

    setState(() => _isSaving = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: Curves.easeIn,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Memory'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Memory Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? 'Memory Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'
                          : 'No date chosen',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFile!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.photo, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Lock for: '),
                  DropdownButton<int>(
                    value: _lockDays,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Unlocked')),
                      DropdownMenuItem(value: 1, child: Text('1 day')),
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                    ],
                    onChanged: (val) => setState(() => _lockDays = val ?? 0),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: _isSaving ? const Text("Saving...") : const Text('Save Memory'),
                  onPressed: _isSaving ? null : _saveMemory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
