import '../contract_support.dart';
import '../profile/birth_details.dart';

final class AskNowBirthData extends ContractValue {
  const AskNowBirthData({this.name, this.birthDetails});
  final String? name;
  final BirthDetails? birthDetails;
  factory AskNowBirthData.fromJson(JsonMap json) => AskNowBirthData(
    name: asString(json['name']),
    birthDetails: BirthDetails.fromJson(json),
  );
  JsonMap toJson() => {'name': name, ...?birthDetails?.toJson()};
  AskNowBirthData copyWith({
    Object? name = contractUnchanged,
    Object? birthDetails = contractUnchanged,
  }) => AskNowBirthData(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    birthDetails: identical(birthDetails, contractUnchanged)
        ? this.birthDetails
        : birthDetails as BirthDetails?,
  );
  @override
  List<Object?> get props => [name, birthDetails];
}

final class AskQuestionRequest extends ContractValue {
  const AskQuestionRequest({this.userId, this.question, this.birth});
  final int? userId;
  final String? question;
  final AskNowBirthData? birth;
  factory AskQuestionRequest.fromJson(JsonMap json) => AskQuestionRequest(
    userId: asInt(json['user_id'] ?? json['userId']),
    question: asString(json['question']),
    birth: asModel(json['birth'], AskNowBirthData.fromJson),
  );
  JsonMap toJson() => {
    'user_id': userId,
    'question': question,
    'birth': birth?.toJson(),
  };
  AskQuestionRequest copyWith({
    Object? userId = contractUnchanged,
    Object? question = contractUnchanged,
    Object? birth = contractUnchanged,
  }) => AskQuestionRequest(
    userId: identical(userId, contractUnchanged) ? this.userId : userId as int?,
    question: identical(question, contractUnchanged)
        ? this.question
        : question as String?,
    birth: identical(birth, contractUnchanged)
        ? this.birth
        : birth as AskNowBirthData?,
  );
  @override
  List<Object?> get props => [userId, question, birth];
}

final class AskAnswerResponse extends ContractValue {
  const AskAnswerResponse({
    this.success,
    this.answer,
    this.remainingTokens,
    this.message,
  });
  final bool? success;
  final String? answer;
  final int? remainingTokens;
  final String? message;
  factory AskAnswerResponse.fromJson(JsonMap json) {
    final rawAnswer = json['answer'];
    final nested = asJsonMap(rawAnswer);
    return AskAnswerResponse(
      success: asBool(json['success']),
      answer: asString(nested?['answer'] ?? rawAnswer),
      remainingTokens: asInt(
        json['remaining_tokens'] ??
            json['remaining'] ??
            json['remaining_questions'] ??
            json['tokens_left'],
      ),
      message: asString(json['message']),
    );
  }
  JsonMap toJson() => {
    'success': success,
    'answer': answer,
    'remaining_tokens': remainingTokens,
    'message': message,
  };
  AskAnswerResponse copyWith({
    Object? success = contractUnchanged,
    Object? answer = contractUnchanged,
    Object? remainingTokens = contractUnchanged,
    Object? message = contractUnchanged,
  }) => AskAnswerResponse(
    success: identical(success, contractUnchanged)
        ? this.success
        : success as bool?,
    answer: identical(answer, contractUnchanged)
        ? this.answer
        : answer as String?,
    remainingTokens: identical(remainingTokens, contractUnchanged)
        ? this.remainingTokens
        : remainingTokens as int?,
    message: identical(message, contractUnchanged)
        ? this.message
        : message as String?,
  );
  @override
  List<Object?> get props => [success, answer, remainingTokens, message];
}

final class AskNowStatus extends ContractValue {
  const AskNowStatus({
    this.freeAvailable,
    this.freeUsedToday,
    this.remainingTokens,
  });
  final bool? freeAvailable;
  final bool? freeUsedToday;
  final int? remainingTokens;
  factory AskNowStatus.fromJson(JsonMap json) => AskNowStatus(
    freeAvailable: asBool(json['free_available']),
    freeUsedToday: asBool(json['free_used_today']),
    remainingTokens: asInt(
      json['remaining_tokens'] ?? json['remaining'] ?? json['tokens_left'],
    ),
  );
  JsonMap toJson() => {
    'free_available': freeAvailable,
    'free_used_today': freeUsedToday,
    'remaining_tokens': remainingTokens,
  };
  AskNowStatus copyWith({
    Object? freeAvailable = contractUnchanged,
    Object? freeUsedToday = contractUnchanged,
    Object? remainingTokens = contractUnchanged,
  }) => AskNowStatus(
    freeAvailable: identical(freeAvailable, contractUnchanged)
        ? this.freeAvailable
        : freeAvailable as bool?,
    freeUsedToday: identical(freeUsedToday, contractUnchanged)
        ? this.freeUsedToday
        : freeUsedToday as bool?,
    remainingTokens: identical(remainingTokens, contractUnchanged)
        ? this.remainingTokens
        : remainingTokens as int?,
  );
  @override
  List<Object?> get props => [freeAvailable, freeUsedToday, remainingTokens];
}

final class RewardQuestionResponse extends ContractValue {
  const RewardQuestionResponse({
    this.success,
    this.addedTokens,
    this.totalTokens,
  });
  final bool? success;
  final int? addedTokens;
  final int? totalTokens;
  factory RewardQuestionResponse.fromJson(JsonMap json) =>
      RewardQuestionResponse(
        success: asBool(json['success']),
        addedTokens: asInt(
          json['added_tokens'] ?? json['added'] ?? json['reward'],
        ),
        totalTokens: asInt(
          json['total_tokens'] ?? json['remaining_tokens'] ?? json['remaining'],
        ),
      );
  JsonMap toJson() => {
    'success': success,
    'added_tokens': addedTokens,
    'total_tokens': totalTokens,
  };
  RewardQuestionResponse copyWith({
    Object? success = contractUnchanged,
    Object? addedTokens = contractUnchanged,
    Object? totalTokens = contractUnchanged,
  }) => RewardQuestionResponse(
    success: identical(success, contractUnchanged)
        ? this.success
        : success as bool?,
    addedTokens: identical(addedTokens, contractUnchanged)
        ? this.addedTokens
        : addedTokens as int?,
    totalTokens: identical(totalTokens, contractUnchanged)
        ? this.totalTokens
        : totalTokens as int?,
  );
  @override
  List<Object?> get props => [success, addedTokens, totalTokens];
}

final class ChatMessage extends ContractValue {
  const ChatMessage({this.sender, this.text, this.createdAt});
  final String? sender;
  final String? text;
  final Object? createdAt;
  factory ChatMessage.fromJson(JsonMap json) => ChatMessage(
    sender: asString(json['sender']),
    text: asString(json['text']),
    createdAt: json['created_at'] ?? json['createdAt'],
  );
  JsonMap toJson() => {'sender': sender, 'text': text, 'created_at': createdAt};
  ChatMessage copyWith({
    Object? sender = contractUnchanged,
    Object? text = contractUnchanged,
    Object? createdAt = contractUnchanged,
  }) => ChatMessage(
    sender: identical(sender, contractUnchanged)
        ? this.sender
        : sender as String?,
    text: identical(text, contractUnchanged) ? this.text : text as String?,
    createdAt: identical(createdAt, contractUnchanged)
        ? this.createdAt
        : createdAt,
  );
  @override
  List<Object?> get props => [sender, text, createdAt];
}

final class ChatPackProduct extends ContractValue {
  const ChatPackProduct({this.productId, this.title, this.price, this.tokens});
  final String? productId;
  final String? title;
  final String? price;
  final int? tokens;
  factory ChatPackProduct.fromJson(JsonMap json) => ChatPackProduct(
    productId: stringFrom(json, const ['product_id', 'productId', 'id']),
    title: asString(json['title']),
    price: asString(json['price']),
    tokens: asInt(json['tokens'] ?? json['questions']),
  );
  JsonMap toJson() => {
    'product_id': productId,
    'title': title,
    'price': price,
    'tokens': tokens,
  };
  ChatPackProduct copyWith({
    Object? productId = contractUnchanged,
    Object? title = contractUnchanged,
    Object? price = contractUnchanged,
    Object? tokens = contractUnchanged,
  }) => ChatPackProduct(
    productId: identical(productId, contractUnchanged)
        ? this.productId
        : productId as String?,
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    price: identical(price, contractUnchanged) ? this.price : price as String?,
    tokens: identical(tokens, contractUnchanged) ? this.tokens : tokens as int?,
  );
  @override
  List<Object?> get props => [productId, title, price, tokens];
}

final class ChatPackVerificationRequest extends ContractValue {
  const ChatPackVerificationRequest({
    this.userId,
    this.productId,
    this.purchaseToken,
  });
  final int? userId;
  final String? productId;
  final String? purchaseToken;
  factory ChatPackVerificationRequest.fromJson(JsonMap json) =>
      ChatPackVerificationRequest(
        userId: asInt(json['user_id'] ?? json['userId']),
        productId: stringFrom(json, const ['product_id', 'productId']),
        purchaseToken: stringFrom(json, const [
          'purchase_token',
          'purchaseToken',
        ]),
      );
  JsonMap toJson() => {
    'user_id': userId,
    'product_id': productId,
    'purchase_token': purchaseToken,
  };
  ChatPackVerificationRequest copyWith({
    Object? userId = contractUnchanged,
    Object? productId = contractUnchanged,
    Object? purchaseToken = contractUnchanged,
  }) => ChatPackVerificationRequest(
    userId: identical(userId, contractUnchanged) ? this.userId : userId as int?,
    productId: identical(productId, contractUnchanged)
        ? this.productId
        : productId as String?,
    purchaseToken: identical(purchaseToken, contractUnchanged)
        ? this.purchaseToken
        : purchaseToken as String?,
  );
  @override
  List<Object?> get props => [userId, productId, purchaseToken];
}

final class ChatPackVerificationResult extends ContractValue {
  const ChatPackVerificationResult({
    this.success,
    this.remainingTokens,
    this.message,
  });
  final bool? success;
  final int? remainingTokens;
  final String? message;
  factory ChatPackVerificationResult.fromJson(JsonMap json) =>
      ChatPackVerificationResult(
        success: asBool(json['success'] ?? json['ok']),
        remainingTokens: asInt(
          json['remaining_tokens'] ?? json['total_tokens'] ?? json['remaining'],
        ),
        message: asString(json['message']),
      );
  JsonMap toJson() => {
    'success': success,
    'remaining_tokens': remainingTokens,
    'message': message,
  };
  ChatPackVerificationResult copyWith({
    Object? success = contractUnchanged,
    Object? remainingTokens = contractUnchanged,
    Object? message = contractUnchanged,
  }) => ChatPackVerificationResult(
    success: identical(success, contractUnchanged)
        ? this.success
        : success as bool?,
    remainingTokens: identical(remainingTokens, contractUnchanged)
        ? this.remainingTokens
        : remainingTokens as int?,
    message: identical(message, contractUnchanged)
        ? this.message
        : message as String?,
  );
  @override
  List<Object?> get props => [success, remainingTokens, message];
}
