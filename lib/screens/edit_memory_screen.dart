import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import '../models/memory.dart';

class EditMemoryScreen extends StatefulWidget {
  final Memory memory;

  const EditMemoryScreen({super.key, required this.memory});

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  File? _imageFile;
  int _lockDays = 0; // 0 = unlocked
  DateTime? _lockedUntil;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memory.title);
    _selectedDate = widget.memory.date;
    _imageFile = (widget.memory.imagePath != null && widget.memory.imagePath!.isNotEmpty)
        ? File(widget.memory.imagePath!)
        : null;

    if (widget.memory.lockedUntil != null &&
        widget.memory.lockedUntil!.isAfter(DateTime.now())) {
      _lockedUntil = widget.memory.lockedUntil;
      _lockDays = _lockedUntil!.difference(DateTime.now()).inDays + 1; // Approximate
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

    DateTime? lockedUntil;
    if (_lockDays > 0) {
      lockedUntil = DateTime.now().add(Duration(days: _lockDays));
    }

    widget.memory.title = title;
    widget.memory.date = date;
    widget.memory.imagePath = _imageFile?.path;
    widget.memory.lockedUntil = lockedUntil;

    await widget.memory.save();

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context); // Return to details screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Memory'),
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
                    'Memory Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
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
                label: _isSaving ? const Text("Saving...") : const Text('Save Changes'),
                onPressed: _isSaving ? null : _saveMemory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
