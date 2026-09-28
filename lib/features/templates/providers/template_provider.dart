import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/storage_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/command_template.dart';

final templateProvider =
    StateNotifierProvider<TemplateNotifier, List<CommandTemplate>>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return TemplateNotifier(storage);
    });

class TemplateNotifier extends StateNotifier<List<CommandTemplate>> {
  final StorageService _storage;
  final _uuid = const Uuid();

  TemplateNotifier(this._storage) : super(CommandTemplate.defaultTemplates) {
    _loadTemplates();
  }

  void _loadTemplates() {
    final saved = _storage.getSavedTemplates();
    if (saved.isNotEmpty) {
      final userTemplates = saved
          .map((m) => CommandTemplate.fromJson(m))
          .toList();
      state = [...CommandTemplate.defaultTemplates, ...userTemplates];
    }
  }

  Future<void> addTemplate({
    required String name,
    required String description,
    required String templateArgs,
  }) async {
    final newTemplate = CommandTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      templateArgs: templateArgs,
      isBuiltIn: false,
    );

    state = [...state, newTemplate];
    await _persist();
  }

  Future<void> updateTemplate(CommandTemplate updated) async {
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
    await _persist();
  }

  Future<void> deleteTemplate(String id) async {
    state = state.where((t) => t.id != id || t.isBuiltIn).toList();
    await _persist();
  }

  Future<void> _persist() async {
    final userOnly = state
        .where((t) => !t.isBuiltIn)
        .map((t) => t.toJson())
        .toList();
    await _storage.saveTemplates(userOnly);
  }
}
