import 'package:flutter/foundation.dart'; // for ChangeNotifier
import 'package:flutter/material.dart';
import 'package:isar/isar.dart'; // for Isar
import 'package:localgpt/schemas/ai_model_model.dart'; // AiModel schema to perform CRUD on it

// A data manipulation handler class to do CRUD operations
class AiModelDb extends ChangeNotifier {
  final Isar _isar; // defininh private isar

  AiModelDb(this._isar); // constructure

  List<AiModel> aiModels = []; // A List of AiModels

  // it refresh the AiModel list
  Future<void> fetchAiModels() async {
    aiModels = await _isar.aiModels
        .where()
        .findAll(); // puting all AiModel in List which are in database
    notifyListeners(); // notifies listners that are looking for value change
  }

  // it defines which AIModel is used by Chat
  Future<void> setActiveModel(int id) async {
    // isar transaction
    await _isar.writeTxn(() async {
      final allModels = await _isar.aiModels
          .where()
          .findAll(); // gettinh AiModel which are in database

      // setting all model's IsLoaded to false which indicates that no model is loaded
      for (final model in allModels) {
        model.isLoaded = false; // all model are now unLoaded / ready to load
        await _isar.aiModels.put(
          model,
        ); // putting modified models in database which updates exixsting one and add if doesn'r
      }

      final activeModel = await _isar.aiModels.get(
        id,
      ); // getting model by ID that is in the database

      // if the model is in database then
      if (activeModel != null) {
        activeModel.isLoaded = true; // make the model's isLoaded state to true
        await _isar.aiModels.put(activeModel); // updating model in database
      }
    });
    await fetchAiModels(); // refreshing
    // 🔍 Debug: see what’s inside DB
    for (final m in aiModels) {
      debugPrint("DB check => ${m.name} : isLoaded=${m.isLoaded}");
    }
  }

  Future<String> getActiveModelName() async {
    final activeModel = await _isar.writeTxn(
      () => _isar.aiModels.filter().isLoadedEqualTo(true).findFirst(),
    );
    final modelName = activeModel != null ? activeModel.name : "Unknown";
    return modelName;
  }

  Future<String> getModleNameById(int modelId) async {
    final model = await _isar.writeTxn(() => _isar.aiModels.get(modelId));
    return model != null ? model.name : "Unknown";
  }

  Future<int> getActiveModelId() async {
    final model = await _isar.aiModels
        .filter()
        .isLoadedEqualTo(true)
        .findFirst();
    return model!.id;
  }

  Future<bool> isAnyModelLoaded() async {
    final isLoaded = await _isar.aiModels
        .filter()
        .isLoadedEqualTo(true)
        .findAll();

    return isLoaded.isNotEmpty ? true : false;
  }

  // handling model ubloading
  Future<void> unloadModel(int id) async {
    final model = await _isar.aiModels.get(
      id,
    ); // getting model that is asked for unload by ID

    // and if the model is in data then
    if (model != null) {
      model.isLoaded =
          false; // setting isModel state to false which indicates model is unloaded

      // doing isar transaction
      await _isar.writeTxn(() async {
        await _isar.aiModels.put(
          model,
        ); // addong/updating model with isLoded to false
      });
      await fetchAiModels(); // refreshing
    }
  }

  Future<void> resetOnStartup() async {
    final models = await _isar.aiModels.where().findAll();
    for (final m in models) {
      m.isLoaded = false;
    }
    await _isar.writeTxn(() => _isar.aiModels.putAll(models));
  }

  // handles adding model to database
  Future<int> addModelToDb(AiModel aiModel) async {
    // getting model's ID that is going to add in database
    final id = await _isar.writeTxn(() async {
      return await _isar.aiModels.put(aiModel); // adding model to database
    });
    await fetchAiModels(); // refreshing
    return id; // returning model ID that can be used later
  }

  // handling deletion of model
  Future<bool> deleteModel(int id) async {
    // if model is delted the it will be true else false
    final deleted = await _isar.writeTxn(() async {
      return await _isar.aiModels.delete(id); // deleting model
    });
    if (deleted) {
      await fetchAiModels(); // refreshing if model is deleted (deleted == false)
      return deleted; // returing true if deleted else false
    } else {
      return false;
    }
  }

  // it helps to clear / delete all the models in the database
}
