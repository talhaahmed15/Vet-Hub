enum InvoicePaymentMethod { cash, card }

enum InvoiceStatus { paid, pending }

enum InvoiceLineItemType { product, service }

class InvoiceLineItem {
  final String id;
  final String name;
  final InvoiceLineItemType type;
  final int quantity;
  final double unitPrice;
  final String? itemId;
  final String? unitLabel;

  const InvoiceLineItem({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    this.itemId,
    this.unitLabel,
  });

  double get total => quantity * unitPrice;

  InvoiceLineItem copyWith({
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    return InvoiceLineItem(
      id: id,
      name: name ?? this.name,
      type: type,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      itemId: itemId,
      unitLabel: unitLabel,
    );
  }
}

class InvoiceDraft {
  final String invoiceId;
  final String invoiceNumber;
  final String? appointmentId;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String petId;
  final String petName;
  final String petSpecies;
  final String petBreed;
  final String petAvatarUrl;
  final bool consultationEnabled;
  final int consultationQty;
  final double consultationPrice;
  final List<InvoiceLineItem> items;
  final InvoicePaymentMethod paymentMethod;
  final double taxRate;

  const InvoiceDraft({
    this.invoiceId = '',
    required this.invoiceNumber,
    this.appointmentId,
    this.clientId = '',
    this.clientName = '',
    this.clientPhone = '',
    this.petId = '',
    this.petName = '',
    this.petSpecies = '',
    this.petBreed = '',
    this.petAvatarUrl = '',
    this.consultationEnabled = false,
    this.consultationQty = 1,
    this.consultationPrice = 45,
    this.items = const [],
    this.paymentMethod = InvoicePaymentMethod.cash,
    this.taxRate = 0,
  });

  bool get hasPet => petName.trim().isNotEmpty;

  double get consultationTotal =>
      consultationEnabled ? consultationQty * consultationPrice : 0;

  double get itemsSubtotal =>
      items.fold(0, (sum, item) => sum + item.total);

  double get subtotal => itemsSubtotal + consultationTotal;

  double get tax => 0;

  double get total => subtotal;

  InvoiceDraft copyWith({
    String? invoiceId,
    String? invoiceNumber,
    String? appointmentId,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? petId,
    String? petName,
    String? petSpecies,
    String? petBreed,
    String? petAvatarUrl,
    bool? consultationEnabled,
    int? consultationQty,
    double? consultationPrice,
    List<InvoiceLineItem>? items,
    InvoicePaymentMethod? paymentMethod,
    double? taxRate,
  }) {
    return InvoiceDraft(
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      appointmentId: appointmentId ?? this.appointmentId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petSpecies: petSpecies ?? this.petSpecies,
      petBreed: petBreed ?? this.petBreed,
      petAvatarUrl: petAvatarUrl ?? this.petAvatarUrl,
      consultationEnabled: consultationEnabled ?? this.consultationEnabled,
      consultationQty: consultationQty ?? this.consultationQty,
      consultationPrice: consultationPrice ?? this.consultationPrice,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}

class InvoiceListItem {
  final String id;
  final String invoiceNumber;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String petId;
  final String petName;
  final double total;
  final InvoiceStatus status;
  final InvoicePaymentMethod paymentMethod;
  final DateTime createdAt;

  const InvoiceListItem({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.petId,
    required this.petName,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });
}
