import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/quotes.json');
  final data = jsonDecode(file.readAsStringSync()) as List;
  final counts = <String, int>{};
  
  for (final quote in data) {
    final author = quote['author'] as String? ?? 'Unknown';
    counts[author] = (counts[author] ?? 0) + 1;
  }
  
  final sortedCounts = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  print('Author Quote Counts:');
  print('-------------------');
  for (final entry in sortedCounts) {
    print('${entry.key}: ${entry.value}');
  }
}
