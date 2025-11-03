import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class PendingAction extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String actionType;
  @HiveField(2)
  final Map<String, dynamic> payload;
  @HiveField(3)
  final String? idempotencyKey;
  @HiveField(4)
  final DateTime updatedAt;

  PendingAction({
    required this.id,
    required this.actionType,
    required this.payload,
    this.idempotencyKey,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType,
      'payload': payload,
      'idempotencyKey': idempotencyKey,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}

