import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== 🤖 ULTIMATE AUTO-MAPPER START ===\n');

  print('Lade TCGdex Sets...');
  final dexResponse = await http.get(Uri.parse('https://api.tcgdex.net/v2/en/sets'));
  final List<dynamic> dexSets = jsonDecode(dexResponse.body);

  print('Lade PokemonTCG.io Sets...');
  final ptcgResponse = await http.get(Uri.parse('https://api.pokemontcg.io/v2/sets'));
  final List<dynamic> ptcgSetsData = jsonDecode(ptcgResponse.body)['data'];

  print('Starte automatischen Abgleich...\n');
  int matched = 0;
  int dexOnly = 0;
  int ptcgOnly = 0;
  int skipped = 0;
  
  final Set<String> matchedPtcgIds = {};
  
  final StringBuffer dartCode = StringBuffer();
  dartCode.writeln('// Automatisch generiertes Mapping (Beinhaltet TCGdex UND PTCG-exklusive Sets):');
  dartCode.writeln('final List<Map<String, String?>> initialMappings = [');

  // --- 1. DURCHLAUF: TCGDEX als Basis ---
  for (var dexSet in dexSets) {
    final setId = dexSet['id'].toString();
    final serieData = dexSet['serie'];
    final serieId = (serieData is Map) ? serieData['id'] ?? '' : '';

    // Pocket, Jumbo, etc. überspringen
    if (serieId == 'jumbo' || setId == 'xya' || setId == 'sp' || serieId == 'tcgp') {
      skipped++;
      continue; 
    }

    final dexNameOrig = dexSet['name'].toString(); // Der echte Name für den Kommentar
    final dexName = dexNameOrig.toLowerCase().trim();

    var bestMatch = ptcgSetsData.where((pSet) {
      final pName = pSet['name'].toString().toLowerCase().trim();
      final pId = pSet['id'].toString().toLowerCase().trim();
      
      if (pName == dexName) return true;
      if (dexName == 'base set' && pName == 'base') return true;
      if (setId == pId) return true;
      return false;
    }).toList();

    if (bestMatch.isNotEmpty) {
      final ptcgId = bestMatch.first['id'].toString();
      final ptcgCode = bestMatch.first['ptcgoCode']?.toString() ?? ''; 
      final ptcgNameOrig = bestMatch.first['name'].toString(); // Echter Name PTCG
      
      dartCode.writeln('  {"tcgdexId": "$setId", "ptcgId": "$ptcgId", "cmCode": "${ptcgCode.isNotEmpty ? ptcgCode : ''}"}, // TCGdex: $dexNameOrig | PTCG: $ptcgNameOrig');
      matchedPtcgIds.add(ptcgId); 
      matched++;
    } else {
      dartCode.writeln('  {"tcgdexId": "$setId", "ptcgId": null, "cmCode": null}, // NUR BEI TCGDEX: $dexNameOrig');
      dexOnly++;
    }
  }

  // --- 2. DURCHLAUF: Übrig gebliebene PokemonTCG.io Sets (Die Exklusiven!) ---
  dartCode.writeln('\n  // --- POKEMONTCG.IO EXKLUSIVE SETS (Promos, neue Releases etc.) ---');
  for (var ptcgSet in ptcgSetsData) {
    final ptcgId = ptcgSet['id'].toString();
    
    if (!matchedPtcgIds.contains(ptcgId)) {
      final ptcgCode = ptcgSet['ptcgoCode']?.toString() ?? '';
      final ptcgNameOrig = ptcgSet['name'].toString();
      
      dartCode.writeln('  {"tcgdexId": "$ptcgId", "ptcgId": "$ptcgId", "cmCode": "${ptcgCode.isNotEmpty ? ptcgCode : ''}"}, // NUR BEI PTCG: $ptcgNameOrig');
      ptcgOnly++;
    }
  }

  dartCode.writeln('];');

  print('\n=== ZUSAMMENFASSUNG ===');
  print('Übersprungene Nonsens-Sets: $skipped');
  print('Gemeinsame Sets (Gematcht): $matched');
  print('Nur bei TCGdex (Lokalisierte Specials): $dexOnly');
  print('Nur bei PokemonTCG.io (Promos/Neue Sets): $ptcgOnly');
  print('\n=== DEIN NEUER DART CODE FÜR DIE APP ===\n');
  
  print(dartCode.toString());
}