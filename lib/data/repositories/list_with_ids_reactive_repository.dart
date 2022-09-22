import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

abstract class ListWithIDsReactiveRepository<T> {
  final updater = PublishSubject<void>();

  Future<List<String>> getRawData();

  Future<bool> saveRawData(final List<String> items);

  T convertFromString(final String rawItem);

  String convertToString(final T item);

  dynamic getId(final T item);

  Stream<List<T>> observeItems() async* {
    yield await getItems();
    await for (final _ in updater) {
      yield await getItems();
    }
  }

  Future<List<T>> getItems() async {
    final rawMemes = await getRawData();
    return rawMemes.map((rawMeme) => convertFromString(rawMeme)).toList();
  }

  Future<bool> setItems(final List<T> items) async {
    final rawItems = items.map((item) => convertToString(item)).toList();
    updater.add(null);
    return saveRawData(rawItems);
  }

  Future<bool> addItemOrReplaceById(final T newItem) async {
    final items = await getItems();
    final itemIndex = items.indexWhere((item) => getId(item) == getId(newItem));
    if (itemIndex != -1) {
      items.removeAt(itemIndex);
      items.insert(itemIndex, newItem);
    } else {
      items.add(newItem);
    }
    return setItems(items);
  }

  Future<bool> addItem(final T newItem) async {
    final items = await getItems();
    items.add(newItem);
    return setItems(items);
  }

  Future<bool> removeFromItemsById(final dynamic id) async {
    final items = await getItems();
    items.removeWhere((item) => getId(item) == id);
    return setItems(items);
  }

  Future<bool> removeItem(final T item) async {
    final items = await getItems();
    items.remove(item);
    return setItems(items);
  }

  Future<T?> getItemById(final dynamic id) async {
    final items = await getItems();
    return items.firstWhereOrNull((item) => getId(item) == id);
  }
}
