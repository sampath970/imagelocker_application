import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/memory.dart';
import 'add_memory_screen.dart';
import 'memory_details_screen.dart';

enum MemoryFilter { all, locked, unlocked }

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  MemoryFilter _filter = MemoryFilter.all;
  String _searchQuery = '';
  late AnimationController _bgController;
  late Animation<Color?> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bgAnimation = ColorTween(
      begin: Colors.blue.shade100,
      end: Colors.blue.shade300,
    ).animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // No need to fade the whole page now, only animate top
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.only(top: 32),
                decoration: BoxDecoration(
                  color: _bgAnimation.value,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            icon: Icon(widget.isDarkMode
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight),
                            onPressed: widget.onToggleTheme,
                            tooltip: widget.isDarkMode ? 'Light mode' : 'Dark mode',
                          ),
                          IconButton(
                            icon: const Icon(Icons.lock),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/auth');
                            },
                            tooltip: 'Lock App',
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Your Memories',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            labelText: 'Search memories...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _filter == MemoryFilter.all,
                              onSelected: (_) => setState(() => _filter = MemoryFilter.all),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Locked'),
                              selected: _filter == MemoryFilter.locked,
                              onSelected: (_) => setState(() => _filter = MemoryFilter.locked),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Unlocked'),
                              selected: _filter == MemoryFilter.unlocked,
                              onSelected: (_) => setState(() => _filter = MemoryFilter.unlocked),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Memory>('memoriesBox').listenable(),
              builder: (context, Box<Memory> box, _) {
                List<Memory> memories = box.values.toList().cast<Memory>();

                if (_filter == MemoryFilter.locked) {
                  memories = memories.where((m) =>
                  m.lockedUntil != null && m.lockedUntil!.isAfter(DateTime.now())
                  ).toList();
                } else if (_filter == MemoryFilter.unlocked) {
                  memories = memories.where((m) =>
                  m.lockedUntil == null || m.lockedUntil!.isBefore(DateTime.now())
                  ).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  memories = memories.where((m) =>
                      m.title.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (memories.isEmpty) {
                  return const Center(
                    child: Text('No memories yet.', style: TextStyle(fontSize: 20)),
                  );
                }

                return ListView.separated(
                  itemCount: memories.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final memory = memories[index];
                    final isLocked = memory.lockedUntil != null &&
                        memory.lockedUntil!.isAfter(DateTime.now());
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      tween: Tween(begin: 1.0, end: 0.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(40 * value, 0),
                          child: Opacity(opacity: 1 - value, child: child!),
                        );
                      },
                      child: ListTile(
                        leading: Icon(
                          isLocked ? Icons.lock : Icons.memory,
                          color: colorScheme.primary,
                        ),
                        title: Text(memory.title),
                        subtitle: Text('Date: ${memory.date.toLocal().toString().split(' ')[0]}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemoryDetailsScreen(memory: memory),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
          );
        },
        tooltip: 'Add Memory',
        child: const Icon(Icons.add),
      ),
    );
  }
}
