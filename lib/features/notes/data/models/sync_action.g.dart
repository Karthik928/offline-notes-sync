part of 'sync_action.dart';

class SyncActionAdapter extends TypeAdapter<SyncAction> {
  @override
  final typeId = 3;

  @override
  SyncAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncAction.create;
      case 1:
        return SyncAction.update;
      case 2:
        return SyncAction.delete;
      default:
        return SyncAction.create;
    }
  }

  @override
  void write(BinaryWriter writer, SyncAction obj) {
    switch (obj) {
      case SyncAction.create:
        writer.writeByte(0);
      case SyncAction.update:
        writer.writeByte(1);
      case SyncAction.delete:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
