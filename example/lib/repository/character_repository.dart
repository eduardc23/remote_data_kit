import 'package:remote_data_kit/remote_data_kit.dart';
import '../data/datasources/character_remote_data_source.dart';
import '../data/models/character_response_model.dart';
import '../failures/failures.dart';

abstract class CharacterRepository {
  Future<PaginatedResponse<Character>> getCharacters({int page = 1});
}

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterRemoteDataSource _dataSource;

  CharacterRepositoryImpl(this._dataSource);

  @override
  Future<PaginatedResponse<Character>> getCharacters({int page = 1}) async {
    try {
      final response = await _dataSource.getCharacters(page: page);
      
      return PaginatedResponse(
        items: response.results,
        hasNextPage: response.info.next != null,
        currentPage: page,
        totalPages: response.info.pages,
      );
    } catch (e) {
      throw e.toFailure();
    }
  }
}
