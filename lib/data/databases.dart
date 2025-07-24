import 'package:hive_flutter/adapters.dart';

part 'databases.g.dart';

@HiveType(typeId: 14) //todo type id should be unique for each model
class PurchaseDetailsSave extends HiveObject {
  @HiveField(1)
  dynamic purchaseID;
  @HiveField(2, defaultValue: "")
  String productID = "";
  @HiveField(3, defaultValue: "")
  String productTitle = "";
  @HiveField(4, defaultValue: "")
  String verificationData = "";
  @HiveField(5)
  DateTime transactionDate = DateTime.now();
  @HiveField(6)
  DateTime expireDate;
  @HiveField(7, defaultValue: false)
  bool status = false;

  PurchaseDetailsSave({
    required this.purchaseID,
    required this.productID,
    required this.productTitle,
    required this.verificationData,
    required this.transactionDate,
    required this.expireDate,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    "purchaseID": purchaseID,
    "productID": productID,
    "productTitle": productTitle,
    "verificationData": verificationData,
    "transactionDate": transactionDate,
    "expireDate": expireDate,
    "status": status,
  };
}
