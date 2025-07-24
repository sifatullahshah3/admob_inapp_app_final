part of 'databases.dart';

class PurchaseDetailsSaveAdapter extends TypeAdapter<PurchaseDetailsSave> {
  @override
  final int typeId = 14;

  @override
  PurchaseDetailsSave read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseDetailsSave(
      purchaseID: fields[1] as dynamic,
      productID: fields[2] as String,
      productTitle: fields[3] as String,
      verificationData: fields[4] as String,
      transactionDate: fields[5] as DateTime,
      expireDate: fields[6] as DateTime,
      status: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseDetailsSave obj) {
    writer
      ..writeByte(7)
      ..writeByte(1)
      ..write(obj.purchaseID)
      ..writeByte(2)
      ..write(obj.productID)
      ..writeByte(3)
      ..write(obj.productTitle)
      ..writeByte(4)
      ..write(obj.verificationData)
      ..writeByte(5)
      ..write(obj.transactionDate)
      ..writeByte(6)
      ..write(obj.expireDate)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseDetailsSaveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
