import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PokemonListScreen(),
    );
  }
}

// ===============================
// 1st Screen: Pokemon List Screen
// ===============================
class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List<dynamic> pokemons = [];
  int offset = 0;
  bool isLoading = false;
  bool isGrid = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=20&offset=$offset'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      setState(() {
        pokemons.addAll(jsonData['results']);
        offset += 20;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      throw Exception('Failed to load Pokémon');
    }
  }

  String getPokemonImageUrl(int index) {
    final id = index + 1;
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
  }

  Widget buildItem(BuildContext context, int index) {
    final pokemon = pokemons[index];
    final name = pokemon['name'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PokemonDetailScreen(
            name: name,
            url: pokemon['url'],
            imageUrl: getPokemonImageUrl(index),
            heroTag: name,
          ),
        ),
      ),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: name,
              child: Image.network(
                getPokemonImageUrl(index),
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '#${index + 1}  ${name.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => isGrid = !isGrid),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: pokemons.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!isLoading &&
                          scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                        getData();
                      }
                      return false;
                    },
                    child: isGrid
                        ? GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: pokemons.length,
                            itemBuilder: buildItem,
                          )
                        : ListView.builder(
                            itemCount: pokemons.length,
                            itemBuilder: buildItem,
                          ),
                  ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

// ===============================
// 2nd Screen: Pokemon Detail Screen
// ===============================
class PokemonDetailScreen extends StatefulWidget {
  final String name;
  final String url;
  final String imageUrl;
  final String heroTag;

  const PokemonDetailScreen({
    super.key,
    required this.name,
    required this.url,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  Map<String, dynamic>? pokemonData;

  @override
  void initState() {
    super.initState();
    fetchPokemonDetail();
  }

  Future<void> fetchPokemonDetail() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode == 200) {
      setState(() {
        pokemonData = jsonDecode(response.body);
      });
    } else {
      throw Exception('Failed to load Pokémon detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name.toUpperCase()),
      ),
      body: pokemonData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: widget.heroTag,
                    child: Image.network(
                      widget.imageUrl,
                      width: 180,
                      height: 180,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildInfoRow('ID', pokemonData!['id'].toString()),
                          buildInfoRow('Height',
                              (pokemonData!['height'] / 10).toString() + ' m'),
                          buildInfoRow('Weight',
                              (pokemonData!['weight'] / 10).toString() + ' kg'),
                          const SizedBox(height: 12),
                          const Text(
                            'Types',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8,
                            children: (pokemonData!['types'] as List)
                                .map((t) => Chip(
                                      label: Text(t['type']['name']),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Abilities',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8,
                            children: (pokemonData!['abilities'] as List)
                                .map((a) => Chip(
                                      label: Text(a['ability']['name']),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Stats',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Column(
                            children: (pokemonData!['stats'] as List)
                                .map(
                                  (s) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(s['stat']['name']),
                                        Text(s['base_stat'].toString()),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
