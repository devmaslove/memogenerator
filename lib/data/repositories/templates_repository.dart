import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';

class TemplatesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  static TemplatesRepository? _instance;

  factory TemplatesRepository.getInstance() => _instance ??=
      TemplatesRepository._internal(SharedPreferenceData.getInstance());

  TemplatesRepository._internal(this.spData);

  Future<bool> addToTemplates(final Template newTemplate) async {
    final templates = await getTemplates();
    final templateIndex =
        templates.indexWhere((template) => template.id == newTemplate.id);
    if (templateIndex != -1) {
      templates.removeAt(templateIndex);
      templates.insert(templateIndex, newTemplate);
      // templates[templateIndex] = newTemplate;
    } else {
      templates.add(newTemplate);
    }
    return _setTemplates(templates);
  }

  Future<bool> removeFromTemplates(final String id) async {
    final templates = await getTemplates();
    templates.removeWhere((template) => template.id == id);
    return _setTemplates(templates);
  }

  Future<bool> updateTemplate(final Template template) async {
    final templates = await getTemplates();
    int pos = templates.indexWhere((element) => element.id == template.id);
    if (pos != -1) {
      templates[pos] = template;
      return _setTemplates(templates);
    }
    return false;
  }

  Future<Template?> getTemplate(final String id) async {
    final templates = await getTemplates();
    return templates.firstWhereOrNull((template) => template.id == id);
  }

  Stream<List<Template>> observeTemplates() async* {
    yield await getTemplates();
    await for (final _ in updater) {
      yield await getTemplates();
    }
  }

  Future<List<Template>> getTemplates() async {
    final rawTemplates = await spData.getTemplates();
    return rawTemplates
        .map((rawTemplate) => Template.fromJson(json.decode(rawTemplate)))
        .toList();
  }

  Future<bool> _setTemplates(List<Template> templates) async {
    final rawTemplates =
        templates.map((template) => json.encode(template.toJson())).toList();
    updater.add(null);
    return spData.setTemplates(rawTemplates);
  }
}
