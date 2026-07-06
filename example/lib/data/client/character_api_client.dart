import 'package:remote_data_kit/remote_data_kit.dart';
import 'package:retrofit/retrofit.dart';
import '../models/character_response_model.dart';

part 'character_api_client.g.dart';

@RestApi()
abstract class CharacterApiClient {
  factory CharacterApiClient(Dio dio, {String baseUrl}) = _CharacterApiClient;

  @GET('/character')
  Future<CharacterResponseModel> getCharacters({
    @Query('page') int? page,
  });
}
