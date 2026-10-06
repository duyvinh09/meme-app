import 'package:cloud_firestore/cloud_firestore.dart';

class PollOptionModel {
  final String id;
  final String text;
  final List<String> voterIds;

  const PollOptionModel({
    required this.id,
    required this.text,
    this.voterIds = const [],
  });

  int get voteCount => voterIds.length;

  factory PollOptionModel.fromMap(Map<String, dynamic> map) {
    return PollOptionModel(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      voterIds: (map['voterIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'voterIds': voterIds,
    };
  }

  PollOptionModel copyWith({
    String? id,
    String? text,
    List<String>? voterIds,
  }) {
    return PollOptionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}

class PollModel {
  final String id;
  final String question;
  final String creatorId;
  final String? creatorName;
  final List<PollOptionModel> options;
  final List<String> totalVoterIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PollModel({
    required this.id,
    required this.question,
    required this.creatorId,
    this.creatorName,
    required this.options,
    this.totalVoterIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  int get totalVoters => totalVoterIds.length;

  bool hasVoted(String userId) => totalVoterIds.contains(userId);

  List<String> userSelectedOptionIds(String userId) {
    return options
        .where((opt) => opt.voterIds.contains(userId))
        .map((opt) => opt.id)
        .toList();
  }

  factory PollModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawOptions = map['options'] as List<dynamic>? ?? [];
    final options = rawOptions
        .whereType<Map>()
        .map((e) => PollOptionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final rawVoters = map['totalVoterIds'] as List<dynamic>? ?? [];
    final totalVoterIds = rawVoters.map((e) => e.toString()).toList();

    return PollModel(
      id: id ?? map['id']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      creatorName: map['creatorName']?.toString(),
      options: options,
      totalVoterIds: totalVoterIds,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'creatorId': creatorId,
      if (creatorName != null) 'creatorName': creatorName,
      'options': options.map((e) => e.toMap()).toList(),
      'totalVoterIds': totalVoterIds,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  PollModel copyWith({
    String? id,
    String? question,
    String? creatorId,
    String? creatorName,
    List<PollOptionModel>? options,
    List<String>? totalVoterIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PollModel(
      id: id ?? this.id,
      question: question ?? this.question,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      options: options ?? this.options,
      totalVoterIds: totalVoterIds ?? this.totalVoterIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
