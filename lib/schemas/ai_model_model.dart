import 'package:isar/isar.dart';

part 'ai_model_model.g.dart';

@collection
class AiModel {
  Id id = Isar.autoIncrement; // auto-incremented

  late String name;
  late String filePath;
  late String size; // in bytes
  late String parameters;
  late DateTime dateAdded;
  bool isLoaded = false;
}
