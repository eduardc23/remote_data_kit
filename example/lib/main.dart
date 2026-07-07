import 'package:flutter/material.dart';
import 'package:remote_data_kit/remote_data_kit.dart';
import 'data/datasources/character_remote_data_source.dart';
import 'repository/character_repository.dart';
import 'ui/character_screen.dart';

void main() {
  // Initialization
  final kit = RemoteDataKit.create(
    baseUrl: 'https://rickandmortyapi.com/api/',
  );

  final dataSource = CharacterRemoteDataSourceImpl(kit);
  final repository = CharacterRepositoryImpl(dataSource);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final CharacterRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Data Kit Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: CharacterScreen(repository: repository),
    );
  }
}
