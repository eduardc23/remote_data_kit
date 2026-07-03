import 'package:dio/dio.dart';
import 'package:remote_data_kit/remote_data_kit.dart';
import '../client/character_api_client.dart';
import '../models/character_response_model.dart';

abstract class CharacterRemoteDataSource {
  Future<CharacterResponseModel> getCharacters({int? page});
}

class CharacterRemoteDataSourceImpl implements CharacterRemoteDataSource {
  final CharacterApiClient _client;
  final DioExceptionMapper _mapper;

  CharacterRemoteDataSourceImpl(this._client, this._mapper);

  @override
  Future<CharacterResponseModel> getCharacters({int? page}) async {
    try {
      return await _client.getCharacters(page: page);
    } on DioException catch (e) {
      throw _mapper.map(e);
    }
  }
}
