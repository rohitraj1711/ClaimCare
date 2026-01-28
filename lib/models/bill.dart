import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Bill model representing an individual bill item within a claim.
/// Bills are stored as a subcollection under claims.
class Bill {
  final String id;
  final String claimId;
  final String type;
  final double amount;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const Bill({
    required this.id,
    required this.claimId,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Create a Bill from Firestore document
  factory Bill.fromFirestore(DocumentSnapshot doc, String claimId) {
    final data = doc.data() as Map<String, dynamic>;
    return Bill(
      id: doc.id,
      claimId: claimId,
      type: data['type'] ?? 'ROOM',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      createdBy: data['createdBy'],
    );
  }

  /// Convert Bill to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
    };
  }

  /// Get BillType enum from type string
  BillType get billType => BillType.fromString(type);

  /// Get type display label
  String get typeLabel => billType.label;

  /// CopyWith method for immutability
  Bill copyWith({
    String? id,
    String? claimId,
    String? type,
    double? amount,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Bill(
      id: id ?? this.id,
      claimId: claimId ?? this.claimId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Empty bill for initialization
Bill emptyBill(String claimId) => Bill(
  id: '',
  claimId: claimId,
  type: 'ROOM',
  amount: 0.0,
  createdAt: DateTime.now(),
);
