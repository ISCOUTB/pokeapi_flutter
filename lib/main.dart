import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Battle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pokémon Battle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, dynamic>? pokemon1;
  Map<String, dynamic>? pokemon2;
  int pokemon1Hp = 0;
  int pokemon2Hp = 0;
  String battleLog = '';
  bool isBattleInProgress = false;

  Future<void> fetchPokemonData(int id, int pokemonIndex) async {
    final url = 'https://pokeapi.co/api/v2/pokemon/$id';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (pokemonIndex == 1) {
          pokemon1 = data;
          pokemon1Hp = data['stats'][0]['base_stat']; // HP inicial del Pokémon 1
        } else {
          pokemon2 = data;
          pokemon2Hp = data['stats'][0]['base_stat']; // HP inicial del Pokémon 2
        }
      });
    }
  }

  void startBattle() {
    final random = Random();
    final pokemonId1 = random.nextInt(1302) + 1;
    final pokemonId2 = random.nextInt(1302) + 1;

    fetchPokemonData(pokemonId1, 1);
    fetchPokemonData(pokemonId2, 2);

    // Limpiamos el log de batalla
    setState(() {
      battleLog = '';
      isBattleInProgress = false;
    });
  }

  Future<void> attackTurn() async {
    if (pokemon1 != null && pokemon2 != null && !isBattleInProgress) {
      setState(() {
        isBattleInProgress = true; // Iniciamos la batalla
      });

      int turns = 10;
      while (turns > 0 && pokemon1Hp > 0 && pokemon2Hp > 0) {
        // Ataque del Pokémon 1 a Pokémon 2
        await Future.delayed(const Duration(seconds: 1)); // Pequeña demora entre golpes
        int pokemon1Attack = pokemon1!['stats'][1]['base_stat'];
        int pokemon2Defense = pokemon2!['stats'][2]['base_stat'];
        int damageToPokemon2 = max(1, pokemon1Attack - pokemon2Defense); // Daño asegurado de al menos 1
        setState(() {
          pokemon2Hp = max(0, pokemon2Hp - damageToPokemon2);
          battleLog += '${pokemon1!['name']} golpea a ${pokemon2!['name']} y le quita $damageToPokemon2 de vida.\n';
        });

        if (pokemon2Hp <= 0) {
          setState(() {
            battleLog += '${pokemon2!['name']} ha sido derrotado!\n';
            announceWinner();
          });
          break;
        }

        // Ataque del Pokémon 2 a Pokémon 1
        await Future.delayed(const Duration(seconds: 1));
        int pokemon2Attack = pokemon2!['stats'][1]['base_stat'];
        int pokemon1Defense = pokemon1!['stats'][2]['base_stat'];
        int damageToPokemon1 = max(1, pokemon2Attack - pokemon1Defense); // Daño asegurado de al menos 1
        setState(() {
          pokemon1Hp = max(0, pokemon1Hp - damageToPokemon1);
          battleLog += '${pokemon2!['name']} golpea a ${pokemon1!['name']} y le quita $damageToPokemon1 de vida.\n';
        });

        if (pokemon1Hp <= 0) {
          setState(() {
            battleLog += '${pokemon1!['name']} ha sido derrotado!\n';
            announceWinner();
          });
          break;
        }

        turns--;
      }

      if (pokemon1Hp > pokemon2Hp) {
        announceWinner();
      } else if (pokemon2Hp > pokemon1Hp) {
        announceWinner();
      } else {
        setState(() {
          battleLog += '¡La batalla ha terminado en empate!\n';
        });
      }

      setState(() {
        isBattleInProgress = false;
      });
    }
  }

  void announceWinner() {
    if (pokemon1Hp > pokemon2Hp) {
      setState(() {
        battleLog += '${pokemon1!['name']} ha ganado la batalla!\n';
      });
    } else if (pokemon2Hp > pokemon1Hp) {
      setState(() {
        battleLog += '${pokemon2!['name']} ha ganado la batalla!\n';
      });
    }
  }

  Widget displayPokemon(Map<String, dynamic>? pokemon, int hp) {
    if (pokemon == null) {
      return const Text('No Pokémon selected');
    } else {
      return Column(
        children: [
          Image.network(pokemon['sprites']['front_default']),
          Text(pokemon['name'].toString().toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('HP: $hp'),
          Text('Attack: ${pokemon['stats'][1]['base_stat']}'),
          Text('Defense: ${pokemon['stats'][2]['base_stat']}'),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: displayPokemon(pokemon1, pokemon1Hp)),
                const Text("VS", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                Expanded(child: displayPokemon(pokemon2, pokemon2Hp)),
              ],
            ),
            ElevatedButton(
              onPressed: startBattle,
              child: const Text('Select Pokémon'),
            ),
            ElevatedButton(
              onPressed: isBattleInProgress ? null : attackTurn,
              child: const Text('Start Battle'),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  battleLog,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
