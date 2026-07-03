import 'package:flutter/material.dart';
import 'package:remote_data_kit/remote_data_kit.dart';
import '../data/models/character_response_model.dart';
import '../repository/character_repository.dart';
import '../failures/failures.dart';

class CharacterScreen extends StatefulWidget {
  final CharacterRepository repository;
  
  const CharacterScreen({super.key, required this.repository});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  late Future<PaginatedResponse<Character>> _charactersFuture;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  void _loadCharacters() {
    setState(() {
      _charactersFuture = widget.repository.getCharacters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rick & Morty Characters')),
      body: FutureBuilder<PaginatedResponse<Character>>(
        future: _charactersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsetsGeometry.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(snapshot.error!.toUserMessage()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCharacters,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final characters = snapshot.data?.items ?? [];

          return ListView.builder(
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(character.image)),
                title: Text(character.name),
                subtitle: Text('${character.species} - ${character.status}'),
              );
            },
          );
        },
      ),
    );
  }
}
