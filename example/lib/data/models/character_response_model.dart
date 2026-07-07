import 'package:json_annotation/json_annotation.dart';
part 'character_response_model.g.dart';

@JsonSerializable()
class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String image;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.image,
  });

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterToJson(this);
}

@JsonSerializable()
class CharacterResponseModel {
  final List<Character> results;
  final InfoModel info;

  CharacterResponseModel({
    required this.results,
    required this.info,
  });

  factory CharacterResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterResponseModelToJson(this);
}

@JsonSerializable()
class InfoModel {
  final int pages;
  final String? next;

  InfoModel({
    required this.pages,
    this.next,
  });

  factory InfoModel.fromJson(Map<String, dynamic> json) =>
      _$InfoModelFromJson(json);
  Map<String, dynamic> toJson() => _$InfoModelToJson(this);
}
