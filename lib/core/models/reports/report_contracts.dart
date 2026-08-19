import '../contract_support.dart';
import '../love/love_contracts.dart';
import '../profile/birth_details.dart';

final class LocalizedReportContent extends ContractValue {
  const LocalizedReportContent({
    this.title,
    this.description,
    this.shortDescription,
    this.fullDescription,
    this.category,
  });
  final String? title;
  final String? description;
  final String? shortDescription;
  final String? fullDescription;
  final String? category;
  factory LocalizedReportContent.fromJson(JsonMap json) =>
      LocalizedReportContent(
        title: asString(json['title']),
        description: asString(json['description']),
        shortDescription: stringFrom(json, const [
          'short_description',
          'shortDescription',
        ]),
        fullDescription: stringFrom(json, const [
          'fullDescription',
          'full_description',
        ]),
        category: asString(json['category']),
      );
  JsonMap toJson() => {
    'title': title,
    'description': description,
    'short_description': shortDescription,
    'fullDescription': fullDescription,
    'category': category,
  };
  LocalizedReportContent copyWith({
    Object? title = contractUnchanged,
    Object? description = contractUnchanged,
    Object? shortDescription = contractUnchanged,
    Object? fullDescription = contractUnchanged,
    Object? category = contractUnchanged,
  }) => LocalizedReportContent(
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    description: identical(description, contractUnchanged)
        ? this.description
        : description as String?,
    shortDescription: identical(shortDescription, contractUnchanged)
        ? this.shortDescription
        : shortDescription as String?,
    fullDescription: identical(fullDescription, contractUnchanged)
        ? this.fullDescription
        : fullDescription as String?,
    category: identical(category, contractUnchanged)
        ? this.category
        : category as String?,
  );
  @override
  List<Object?> get props => [
    title,
    description,
    shortDescription,
    fullDescription,
    category,
  ];
}

final class ReportCatalogItem extends ContractValue {
  const ReportCatalogItem({
    this.id,
    this.content,
    this.hindiContent,
    this.price,
    this.image,
  });
  final String? id;
  final LocalizedReportContent? content;
  final LocalizedReportContent? hindiContent;
  final double? price;
  final String? image;
  factory ReportCatalogItem.fromJson(JsonMap json) => ReportCatalogItem(
    id: asString(json['id']),
    content: LocalizedReportContent.fromJson(json),
    hindiContent: LocalizedReportContent.fromJson({
      'title': json['title_hi'],
      'description': json['description_hi'],
      'short_description': json['short_description_hi'],
      'fullDescription': json['fullDescription_hi'],
      'category': json['category_hi'],
    }),
    price: asDouble(json['price']),
    image: asString(json['image']),
  );
  JsonMap toJson() {
    final hindi = hindiContent?.toJson();
    return {
      'id': id,
      ...?content?.toJson(),
      'title_hi': hindi?['title'],
      'description_hi': hindi?['description'],
      'short_description_hi': hindi?['short_description'],
      'fullDescription_hi': hindi?['fullDescription'],
      'category_hi': hindi?['category'],
      'price': price,
      'image': image,
    };
  }

  ReportCatalogItem copyWith({
    Object? id = contractUnchanged,
    Object? content = contractUnchanged,
    Object? hindiContent = contractUnchanged,
    Object? price = contractUnchanged,
    Object? image = contractUnchanged,
  }) => ReportCatalogItem(
    id: identical(id, contractUnchanged) ? this.id : id as String?,
    content: identical(content, contractUnchanged)
        ? this.content
        : content as LocalizedReportContent?,
    hindiContent: identical(hindiContent, contractUnchanged)
        ? this.hindiContent
        : hindiContent as LocalizedReportContent?,
    price: identical(price, contractUnchanged) ? this.price : price as double?,
    image: identical(image, contractUnchanged) ? this.image : image as String?,
  );
  @override
  List<Object?> get props => [id, content, hindiContent, price, image];
}

final class ReportSelection extends ContractValue {
  const ReportSelection({this.report});
  final ReportCatalogItem? report;
  factory ReportSelection.fromJson(JsonMap json) => ReportSelection(
    report: ReportCatalogItem.fromJson(asJsonMap(json['report']) ?? json),
  );
  JsonMap toJson() => report?.toJson() ?? const {};
  ReportSelection copyWith({Object? report = contractUnchanged}) =>
      ReportSelection(
        report: identical(report, contractUnchanged)
            ? this.report
            : report as ReportCatalogItem?,
      );
  @override
  List<Object?> get props => [report];
}

final class ReportBirthDetails extends ContractValue {
  const ReportBirthDetails({this.name, this.birthDetails});
  final String? name;
  final BirthDetails? birthDetails;
  factory ReportBirthDetails.fromJson(JsonMap json) => ReportBirthDetails(
    name: asString(json['name']),
    birthDetails: BirthDetails.fromJson({
      ...json,
      'lat': json['lat'] ?? json['latitude'],
      'lng': json['lng'] ?? json['longitude'],
    }),
  );
  JsonMap toJson() => {'name': name, ...?birthDetails?.toJson()};
  ReportBirthDetails copyWith({
    Object? name = contractUnchanged,
    Object? birthDetails = contractUnchanged,
  }) => ReportBirthDetails(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    birthDetails: identical(birthDetails, contractUnchanged)
        ? this.birthDetails
        : birthDetails as BirthDetails?,
  );
  @override
  List<Object?> get props => [name, birthDetails];
}

final class ReportCheckoutDraft extends ContractValue {
  const ReportCheckoutDraft({
    this.name,
    this.email,
    this.phone,
    this.birthDetails,
    this.language,
    this.lovePayload,
  });
  final String? name;
  final String? email;
  final String? phone;
  final BirthDetails? birthDetails;
  final String? language;
  final LoveCompatibilityRequest? lovePayload;
  factory ReportCheckoutDraft.fromJson(JsonMap json) => ReportCheckoutDraft(
    name: asString(json['name']),
    email: asString(json['email']),
    phone: asString(json['phone']),
    birthDetails: BirthDetails.fromJson(json),
    language: stringFrom(json, const ['language', 'lang']),
    lovePayload: asModel(
      json['love_payload'],
      LoveCompatibilityRequest.fromJson,
    ),
  );
  JsonMap toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    ...?birthDetails?.toJson(),
    'language': language,
    'love_payload': lovePayload?.toJson(),
  };
  ReportCheckoutDraft copyWith({
    Object? name = contractUnchanged,
    Object? email = contractUnchanged,
    Object? phone = contractUnchanged,
    Object? birthDetails = contractUnchanged,
    Object? language = contractUnchanged,
    Object? lovePayload = contractUnchanged,
  }) => ReportCheckoutDraft(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    email: identical(email, contractUnchanged) ? this.email : email as String?,
    phone: identical(phone, contractUnchanged) ? this.phone : phone as String?,
    birthDetails: identical(birthDetails, contractUnchanged)
        ? this.birthDetails
        : birthDetails as BirthDetails?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
    lovePayload: identical(lovePayload, contractUnchanged)
        ? this.lovePayload
        : lovePayload as LoveCompatibilityRequest?,
  );
  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    birthDetails,
    language,
    lovePayload,
  ];
}

final class ReportPurchaseReceipt extends ContractValue {
  const ReportPurchaseReceipt({this.product, this.purchaseToken, this.userId});
  final String? product;
  final String? purchaseToken;
  final int? userId;
  factory ReportPurchaseReceipt.fromJson(JsonMap json) => ReportPurchaseReceipt(
    product: stringFrom(json, const ['product', 'product_id']),
    purchaseToken: stringFrom(json, const ['purchase_token', 'purchaseToken']),
    userId: asInt(json['user_id'] ?? json['userId']),
  );
  JsonMap toJson() => {
    'product': product,
    'purchase_token': purchaseToken,
    'user_id': userId,
  };
  ReportPurchaseReceipt copyWith({
    Object? product = contractUnchanged,
    Object? purchaseToken = contractUnchanged,
    Object? userId = contractUnchanged,
  }) => ReportPurchaseReceipt(
    product: identical(product, contractUnchanged)
        ? this.product
        : product as String?,
    purchaseToken: identical(purchaseToken, contractUnchanged)
        ? this.purchaseToken
        : purchaseToken as String?,
    userId: identical(userId, contractUnchanged) ? this.userId : userId as int?,
  );
  @override
  List<Object?> get props => [product, purchaseToken, userId];
}

final class ReportGenerationRequest extends ContractValue {
  const ReportGenerationRequest({
    this.name,
    this.email,
    this.phone,
    this.product,
    this.birthDetails,
    this.purchaseToken,
    this.userId,
    this.language,
    this.productId,
    this.orderId,
  });
  final String? name;
  final String? email;
  final String? phone;
  final String? product;
  final BirthDetails? birthDetails;
  final String? purchaseToken;
  final int? userId;
  final String? language;
  // Google Play One-Time Product Verification -- POST
  // /api/reports/google/confirm requires these alongside purchaseToken:
  // productId is the Play Console product/SKU id (PurchaseDetails.productID),
  // distinct from `product` above (this app's own report-catalog id).
  // orderId is Google's own order identifier for this purchase
  // (PurchaseDetails.purchaseID) -- optional on the wire, included when
  // Play provides one.
  final String? productId;
  final String? orderId;
  factory ReportGenerationRequest.fromJson(JsonMap json) =>
      ReportGenerationRequest(
        name: asString(json['name']),
        email: asString(json['email']),
        phone: asString(json['phone']),
        product: asString(json['product']),
        birthDetails: BirthDetails.fromJson({
          ...json,
          'lat': json['latitude'] ?? json['lat'],
          'lng': json['longitude'] ?? json['lng'],
        }),
        purchaseToken: stringFrom(json, const [
          'purchase_token',
          'purchaseToken',
        ]),
        userId: asInt(json['user_id'] ?? json['userId']),
        language: stringFrom(json, const ['language', 'lang']),
        productId: stringFrom(json, const ['product_id', 'productId']),
        orderId: stringFrom(json, const ['order_id', 'orderId']),
      );
  JsonMap toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'product': product,
    'dob': birthDetails?.dateOfBirth,
    'tob': birthDetails?.timeOfBirth,
    'pob': birthDetails?.placeOfBirth,
    'latitude': birthDetails?.latitude,
    'longitude': birthDetails?.longitude,
    'purchase_token': purchaseToken,
    'user_id': userId,
    'language': language,
    'product_id': productId,
    'order_id': orderId,
  };
  ReportGenerationRequest copyWith({
    Object? name = contractUnchanged,
    Object? email = contractUnchanged,
    Object? phone = contractUnchanged,
    Object? product = contractUnchanged,
    Object? birthDetails = contractUnchanged,
    Object? purchaseToken = contractUnchanged,
    Object? userId = contractUnchanged,
    Object? language = contractUnchanged,
    Object? productId = contractUnchanged,
    Object? orderId = contractUnchanged,
  }) => ReportGenerationRequest(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    email: identical(email, contractUnchanged) ? this.email : email as String?,
    phone: identical(phone, contractUnchanged) ? this.phone : phone as String?,
    product: identical(product, contractUnchanged)
        ? this.product
        : product as String?,
    birthDetails: identical(birthDetails, contractUnchanged)
        ? this.birthDetails
        : birthDetails as BirthDetails?,
    purchaseToken: identical(purchaseToken, contractUnchanged)
        ? this.purchaseToken
        : purchaseToken as String?,
    userId: identical(userId, contractUnchanged) ? this.userId : userId as int?,
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
    productId: identical(productId, contractUnchanged)
        ? this.productId
        : productId as String?,
    orderId: identical(orderId, contractUnchanged)
        ? this.orderId
        : orderId as String?,
  );
  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    product,
    birthDetails,
    purchaseToken,
    userId,
    language,
    productId,
    orderId,
  ];
}

final class RelationshipReportRequest extends ContractValue {
  const RelationshipReportRequest({this.report, this.boyIsUser, this.partner});
  final ReportGenerationRequest? report;
  final bool? boyIsUser;
  final LovePersonInput? partner;
  factory RelationshipReportRequest.fromJson(JsonMap json) =>
      RelationshipReportRequest(
        report: ReportGenerationRequest.fromJson(json),
        boyIsUser: asBool(json['boy_is_user'] ?? json['boyIsUser']),
        partner: asModel(json['partner'], LovePersonInput.fromJson),
      );
  JsonMap toJson() => {
    ...?report?.toJson(),
    'boy_is_user': boyIsUser,
    'partner': partner?.toJson(),
  };
  RelationshipReportRequest copyWith({
    Object? report = contractUnchanged,
    Object? boyIsUser = contractUnchanged,
    Object? partner = contractUnchanged,
  }) => RelationshipReportRequest(
    report: identical(report, contractUnchanged)
        ? this.report
        : report as ReportGenerationRequest?,
    boyIsUser: identical(boyIsUser, contractUnchanged)
        ? this.boyIsUser
        : boyIsUser as bool?,
    partner: identical(partner, contractUnchanged)
        ? this.partner
        : partner as LovePersonInput?,
  );
  @override
  List<Object?> get props => [report, boyIsUser, partner];
}

final class ReportGenerationOutcome extends ContractValue {
  const ReportGenerationOutcome({
    this.success,
    this.reportId,
    this.message,
    this.errorCode,
  });
  final bool? success;
  final String? reportId;
  final String? message;

  /// Structured failure reason from `/api/reports/google/confirm`'s
  /// `error_code` field (Report Purchase CANCELED Recovery fix) --
  /// e.g. "purchase_canceled", "purchase_pending". Null on success and
  /// on any failure the backend hasn't classified (network error,
  /// 5xx, generic verification failure) -- those must stay
  /// indistinguishable from today's plain retryable failure.
  final String? errorCode;
  factory ReportGenerationOutcome.fromJson(JsonMap json) =>
      ReportGenerationOutcome(
        success: asBool(json['success'] ?? json['ok']),
        reportId: stringFrom(json, const ['report_id', 'reportId', 'id']),
        message: asString(json['message']),
        errorCode: stringFrom(json, const ['error_code', 'errorCode']),
      );
  JsonMap toJson() => {
    'success': success,
    'report_id': reportId,
    'message': message,
    'error_code': errorCode,
  };
  ReportGenerationOutcome copyWith({
    Object? success = contractUnchanged,
    Object? reportId = contractUnchanged,
    Object? message = contractUnchanged,
    Object? errorCode = contractUnchanged,
  }) => ReportGenerationOutcome(
    success: identical(success, contractUnchanged)
        ? this.success
        : success as bool?,
    reportId: identical(reportId, contractUnchanged)
        ? this.reportId
        : reportId as String?,
    message: identical(message, contractUnchanged)
        ? this.message
        : message as String?,
    errorCode: identical(errorCode, contractUnchanged)
        ? this.errorCode
        : errorCode as String?,
  );
  @override
  List<Object?> get props => [success, reportId, message, errorCode];
}
