import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== 🔍 POKEMONTCG.IO SET SCANNER ===\n');
  print('Lade alle Sets herunter...');

  final response = await http.get(Uri.parse('https://api.pokemontcg.io/v2/sets'));
  
  if (response.statusCode == 200) {
    final List<dynamic> sets = jsonDecode(response.body)['data'];
    
    print('✅ ${sets.length} Sets gefunden!\n');
    print('ID'.padRight(15) + ' | ' + 'Cardmarket Code'.padRight(15) + ' | ' + 'Name');
    print('-' * 70);

    // Wir sortieren sie alphabetisch nach dem Namen, damit du sie leichter findest
    sets.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

    for (var s in sets) {
      final id = s['id'].toString();
      final cmCode = s['ptcgoCode']?.toString() ?? 'N/A';
      final name = s['name'].toString();
      
      print('${id.padRight(15)} | ${cmCode.padRight(15)} | $name');
    }
    
    print('\n=== SUCHE NACH SPEZIELLEN KARTEN/PROMOS ===');
    
    // Hier können wir gezielt nach dem MEP Promos Set suchen:
    final mepSets = sets.where((s) => s['name'].toString().toLowerCase().contains('promo') || s['id'].toString().toLowerCase().contains('mep')).toList();
    
    if (mepSets.isNotEmpty) {
      print('\nGefundene Promo-Sets:');
      for (var s in mepSets) {
        print('-> [${s['id']}] ${s['name']} (${s['total']} Karten)');
      }
    }

  } else {
    print('❌ API Fehler: ${response.statusCode}');
  }
}