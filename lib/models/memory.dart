import 'package:hive/hive.dart';

part 'memory.g.dart';

@HiveType(typeId: 0)
class Memory extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String? imagePath;

  @HiveField(3)
  DateTime? lockedUntil;

  Memory({
    required this.title,
    required this.date,
    this.imagePath,
    this.lockedUntil,
  });
}
