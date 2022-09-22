import 'dart:convert';

import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/repositories/list_with_ids_reactive_repository.dart';
import 'package:memogenerator/data/shared_preference_data.dart';

class TemplatesRepository extends ListWithIDsReactiveRepository<Template> {
  final SharedPreferenceData spData;

  static TemplatesRepository? _instance;

  factory TemplatesRepository.getInstance() => _instance ??=
      TemplatesRepository._internal(SharedPreferenceData.getInstance());

  TemplatesRepository._internal(this.spData);

  @override
  Template convertFromString(String rawItem) {
    return Template.fromJson(json.decode(rawItem));
  }

  @override
  String convertToString(Template item) {
    return json.encode(item.toJson());
  }

  @override
  getId(Template item) {
    return item.id;
  }

  @override
  Future<List<String>> getRawData() {
    return spData.getTemplates();
  }

  @override
  Future<bool> saveRawData(List<String> items) {
    return spData.setTemplates(items);
  }
}
