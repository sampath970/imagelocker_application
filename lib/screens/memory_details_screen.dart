import 'package:flutter/material.dart';
import '../models/memory.dart';
import 'dart:io';
import 'edit_memory_screen.dart';
import 'package:share_plus/share_plus.dart';

class MemoryDetailsScreen extends StatefulWidget {
  final Memory memory;

  const MemoryDetailsScreen({super.key, required this.memory});

  @override
  State<MemoryDetailsScreen> createState() => _MemoryDetailsScreenState();
}

class _MemoryDetailsScreenState extends State<MemoryDetailsScreen> {
  late Duration _remaining;
  late bool _isLocked;
  late Memory _memory;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
    _updateLockState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    setState(() {
      _updateLockState();
    });
  }

  void _updateLockState() {
    final now = DateTime.now();
    if (_memory.lockedUntil != null && _memory.lockedUntil!.isAfter(now)) {
      _isLocked = true;
      _remaining = _memory.lockedUntil!.difference(now);
    } else {
      _isLocked = false;
      _remaining = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _deleteMemory(BuildContext context) async {
    await _memory.delete();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memory deleted!')),
    );
  }

  Future<void> _shareMemory(BuildContext context) async {
    String text =
        'Memory: ${_memory.title}\nDate: ${_memory.date.toLocal().toString().split(' ')[0]}';
    if (_isLocked) {
      text += "\n(This memory is currently locked.)";
    }
    if (_memory.imagePath != null &&
        _memory.imagePath!.isNotEmpty &&
        File(_memory.imagePath!).existsSync()) {
      await Share.shareXFiles(
        [XFile(_memory.imagePath!)],
        text: text,
        subject: _memory.title,
      );
    } else {
      await Share.share(
        text,
        subject: _memory.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = _remaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => _shareMemory(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditMemoryScreen(memory: _memory),
                ),
              );
              setState(() {
                // Refresh state after editing
                _memory = _memory;
                _updateLockState();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Memory?'),
                  content: const Text('Are you sure you want to delete this memory?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMemory(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLocked
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 56, color: colorScheme.primary),
                  const SizedBox(height: 18),
                  const Text(
                    "This memory is locked!",
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Will unlock in:",
                    style: TextStyle(fontSize: 16, color: colorScheme.secondary),
                  ),
                  const SizedBox(height: 10),
                  // Live timer, fading background
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "${remaining.inDays}d "
                          "${remaining.inHours % 24}h "
                          "${remaining.inMinutes % 60}m "
                          "${remaining.inSeconds % 60}s",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "You can access this memory again\non ${_memory.lockedUntil!.toLocal().toString().split(' ')[0]}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_memory.imagePath != null && _memory.imagePath!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_memory.imagePath!),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      width: double.infinity,
                      height: 120,
                      alignment: Alignment.center,
                      child: const Text("Image not found.", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ),
            Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.title, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _memory.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.today, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          "Date: ${_memory.date.toLocal().toString().split(' ')[0]}",
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    if (_memory.lockedUntil != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Icon(Icons.lock_open, color: colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text(
                              "Unlocked",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Flutter foundation for the ticker:
class Ticker {
  Ticker(this.onTick);

  final void Function(Duration) onTick;
  late final Stopwatch _stopwatch = Stopwatch()..start();
  bool _isActive = false;

  void start() {
    _isActive = true;
    _tick();
  }

  void _tick() async {
    while (_isActive) {
      onTick(_stopwatch.elapsed);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void dispose() {
    _isActive = false;
    _stopwatch.stop();
  }
}
