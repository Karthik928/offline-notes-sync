import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes_sync/features/notes/data/services/queue_service.dart';

void main() {
  test('QueueService uses a shared instance across sync services', () {
    final first = QueueService();
    final second = QueueService();

    expect(first, same(second));
  });
}
