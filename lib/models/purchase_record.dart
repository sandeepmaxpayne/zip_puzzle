class PurchaseRecord {
  const PurchaseRecord({
    required this.productId,
    required this.purchaseId,
    required this.purchaseToken,
    required this.status,
    required this.amountLabel,
    required this.grantedAtIso,
    required this.source,
  });

  final String productId;
  final String purchaseId;
  final String purchaseToken;
  final String status;
  final String amountLabel;
  final String grantedAtIso;
  final String source;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'productId': productId,
        'purchaseId': purchaseId,
        'purchaseToken': purchaseToken,
        'status': status,
        'amountLabel': amountLabel,
        'grantedAtIso': grantedAtIso,
        'source': source,
      };
}
