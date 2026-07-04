
import '../models/sync_operation.dart';
import 'hive_service.dart';

class QueueService {
  final box = HiveService.operationQueue;

  List<SyncOperation> getAll() {
    final list = box.values.toList();

    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return list;
  }

  Future<void> add(SyncOperation operation) async {
    await box.put(operation.id, operation);
  }

  Future<void> remove(String id) async {
    await box.delete(id);
  }

  Future<void> clear() async {
    await box.clear();
  }
}
