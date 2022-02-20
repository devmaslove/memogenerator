import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CopyUniqueFileInteractor {
  static CopyUniqueFileInteractor? _instance;

  factory CopyUniqueFileInteractor.getInstance() =>
      _instance ??= CopyUniqueFileInteractor._internal();

  CopyUniqueFileInteractor._internal();

  Future<String> copyUniqueFile({
    required final String directoryWithFiles,
    required final String filePath,
  }) async {
    // создаем директорию в AppData куда будем сохранять
    final docsPath = await getApplicationDocumentsDirectory();
    final pathToSaveFile =
        "${docsPath.absolute.path}${Platform.pathSeparator}$directoryWithFiles";
    await Directory(pathToSaveFile).create(recursive: true);
    // получаем имя файла и разбираем его на части
    // fileSuffixNum - суффикс (нижнее подчеркивание число '_1')
    // fileExt - расширение файла
    // fileName - имя файла без расширения
    String fileNameWithExt = filePath.split(Platform.pathSeparator).last;
    final fileExt = fileNameWithExt.split(".").last;
    String fileName = fileNameWithExt.substring(
        0, fileNameWithExt.length - fileExt.length - 1);
    int fileSuffixNum = 0;
    if (fileName.contains(RegExp(r"_\d+$"))) {
      final number = fileName.split("_").last;
      fileSuffixNum = int.tryParse(number) ?? 0;
      if (fileSuffixNum != 0) {
        fileName = fileName.substring(0, fileName.length - number.length - 1);
      }
    }
    final file = File(filePath);
    int fileLength = await file.length();
    return _createNewFileIfNeed(
      fileName,
      fileSuffixNum,
      fileExt,
      pathToSaveFile,
      file,
      fileLength,
    );
  }

  Future<String> _createNewFileIfNeed(
    final String fileName,
    final int fileNum,
    final String fileExt,
    final String path,
    final File file,
    final int fileLength,
  ) async {
    final fileNameWithExt =
        fileNum > 0 ? "${fileName}_$fileNum.$fileExt" : "$fileName.$fileExt";
    final fullFileName = "$path${Platform.pathSeparator}$fileNameWithExt";
    final oldFile = File(fullFileName);
    bool exists = await oldFile.exists();
    if (!exists) {
      await file.copy(fullFileName);
      return fullFileName;
    }
    // проверяем размер - если совпадает то считаем что это
    // такойже файл
    int oldLength = await oldFile.length();
    if (oldLength == fileLength) return fullFileName;
    // меняем номер и заного пытаемся сохранить
    return _createNewFileIfNeed(
      fileName,
      fileNum + 1,
      fileExt,
      path,
      file,
      fileLength,
    );
  }
}
