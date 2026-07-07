import 'package:remote_data_kit/remote_data_kit.dart';
import '../models/character_response_model.dart';

abstract class CharacterRemoteDataSource {
  Future<CharacterResponseModel> getCharacters({int? page});
}

class CharacterRemoteDataSourceImpl implements CharacterRemoteDataSource {
  final RemoteDataKit _kit;

  const CharacterRemoteDataSourceImpl(this._kit);

  @override
  Future<CharacterResponseModel> getCharacters({int? page}) async {
    final response = await _kit.get(
      '/character',
      queryParameters: page != null ? {'page': page} : null,
      fromJson: (json) => CharacterResponseModel.fromJson(json),
    );
    return response.data;
  }
}
