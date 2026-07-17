import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chw_augment/models/patient.dart';
import 'package:chw_augment/models/visit.dart';
import 'package:chw_augment/models/visit_note.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  final String _apiKey = dotenv.env['OPENROUTER_API_KEY']!;
  final String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final String _model = 'openai/gpt-4o-mini';

  Future<String> getMedicalAnalysis({
    required Patient patient,
    required List<Visit> visits,
    required Map<String, List<VisitNote>> detailedNotesMap,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'null') {
      throw Exception('OpenRouter API key is not configured. Please add OPENROUTER_API_KEY to your .env file');
    }

    final prompt = _buildMedicalAnalysisPrompt(patient, visits, detailedNotesMap);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/yourusername/chw_augment',
          'X-Title': 'UbuntuHealth Medical Analysis',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''
You are a medical AI assistant for Community Health Workers in rural Kenya.
You can understand and respond in both English and Kiswahili (Swahili).
If the user writes in Kiswahili, respond in Kiswahili. If in English, respond in English.
For medical terms, provide both English and Kiswahili translations when helpful.
Return ONLY plain text ONLY.
Never use markdown symbols like # * _ - • → ** [] () or any formatting.
Use only letters, numbers, colons, commas, periods, and new lines.
Separate sections with one blank line.
Do NOT add any extra text before or after the report.
Follow the exact structure given in the user message.
'''
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'].trim();

        // Final cleanup in case AI adds unwanted symbols
        content = content
            .replaceAll(RegExp(r'[#*_\->•]'), '')
            .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // limit empty lines
            .trim();

        return content;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  String _buildMedicalAnalysisPrompt(
      Patient patient,
      List<Visit> visits,
      Map<String, List<VisitNote>> detailedNotesMap,
      ) {
    final buffer = StringBuffer();

    // Patient info
    buffer.writeln('Patient Information');
    buffer.writeln('ID: ${patient.displayId}');
    buffer.writeln('Name: ${patient.firstName} ${patient.lastName}'); // Changed from patient.name
    buffer.writeln('Gender: ${patient.gender}');
    buffer.writeln('Age: ${patient.age}');
    buffer.writeln('');

    // Visit history summary for AI context
    buffer.writeln('Visit History');
    if (visits.isEmpty) {
      buffer.writeln('No visits recorded');
      // Add the return statement here
      return buffer.toString();
    } else {
      for (var visit in visits) {
        {
          buffer.writeln('Date: ${visit.visitDate}');
          if (visit.notes?.isNotEmpty == true) {
            buffer.writeln('Notes: ${visit.notes}');
          }
          final notes = detailedNotesMap[visit.id] ?? [];
          for (var note in notes) {
            buffer.writeln('Observation: ${note.content}');
          }
          buffer.writeln('');
        }
      }
    }

    // === EXACT OUTPUT TEMPLATE (THIS IS WHAT AI WILL FOLLOW) ===
    buffer.writeln('''
Generate the medical report using EXACTLY this format with no symbols or formatting:

Medical Analysis Report

Patient Summary
Patient ID: ${patient.displayId}
Name: ${patient.firstName} ${patient.lastName} // Changed from patient.name
Gender: ${patient.gender}
Age: ${patient.age}

Visit History Summary
Write 2 to 4 sentences summarizing the patient's visits, appetite, weight, energy levels or any trends observed.

Potential Diseases or Conditions
Condition Name One
Short explanation why this is possible based on symptoms.

Condition Name Two
Another short explanation.

Recommendations
One clear recommendation per line like this
Another practical advice
Suggest follow-up if needed
Encourage healthy habits

Things to Watch Out For
Warning sign one
Warning sign two
Warning sign three
Any serious symptom that needs urgent care

Use only plain text and blank lines to separate sections.
Do not use bullets, arrows, bold, italics, or any special characters.
''');

    return buffer.toString();
  }
}
