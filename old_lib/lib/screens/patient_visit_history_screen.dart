import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chw_augment/models/patient.dart';
import 'package:chw_augment/models/visit.dart';
import 'package:chw_augment/models/visit_note.dart';
import 'package:chw_augment/services/database_helper.dart';
import 'package:chw_augment/services/openrouter_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PatientVisitHistoryScreen extends StatefulWidget {
  final Patient patient;

  const PatientVisitHistoryScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientVisitHistoryScreen> createState() => _PatientVisitHistoryScreenState();
}

class _PatientVisitHistoryScreenState extends State<PatientVisitHistoryScreen> {
  late Future<List<Visit>> _visitsFuture;
  bool _isLoadingAnalysis = false;
  String? _aiAnalysisResult;

  @override
  void initState() {
    super.initState();
    _visitsFuture = _fetchVisits();
  }

  Future<List<Visit>> _fetchVisits() async {
    return await DatabaseHelper().getVisitsForPatient(widget.patient.id);
  }

  String formatDate(DateTime date) => DateFormat('EEE, MMM dd • yyyy').format(date);
  String formatTime(DateTime date) => DateFormat('hh:mm a').format(date);

  // BEAUTIFUL RICH TEXT FOR AI REPORT
  Widget _buildRichAnalysis(String plainText) {
    final lines = plainText.split('\n');
    List<TextSpan> spans = [];

    for (String line in lines) {
      String trimmed = line.trim();

      if (trimmed.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      if (trimmed == 'Medical Analysis Report' ||
          trimmed == 'Patient Summary' ||
          trimmed == 'Visit History Summary' ||
          trimmed == 'Potential Diseases or Conditions' ||
          trimmed == 'Recommendations' ||
          trimmed == 'Things to Watch Out For') {
        spans.add(TextSpan(
          text: '$trimmed\n\n',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
            height: 1.4,
          ),
        ));
      }
      else if (trimmed.startsWith('Patient ID:') ||
          trimmed.startsWith('Name:') ||
          trimmed.startsWith('Gender:') ||
          trimmed.startsWith('Age:')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade800,
          ),
        ));
      }
      else if (spans.isNotEmpty) {
        final lastText = spans.last.text;
        if (lastText != null && lastText.contains('Potential Diseases or Conditions') &&
          trimmed.isNotEmpty &&
          !trimmed.contains(':') &&
          !trimmed.toLowerCase().contains('explanation')) {
          spans.add(TextSpan(
            text: '$trimmed\n',
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.deepOrange,
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: '$line\n',
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.6,
              color: Colors.black87,
            ),
          ));
        }
      }
      else {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            fontSize: 15.5,
            height: 1.6,
            color: Colors.black87,
          ),
        ));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.left,
    );
  }

  List<pw.Widget> _buildPdfRichAnalysis(String plainText) {
    final lines = plainText.split('\n');
    List<pw.Widget> widgets = [];

    for (String line in lines) {
      String trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 12));
        continue;
      }

      if (trimmed == 'Medical Analysis Report' ||
          trimmed == 'Patient Summary' ||
          trimmed == 'Visit History Summary' ||
          trimmed == 'Potential Diseases or Conditions' ||
          trimmed == 'Recommendations' ||
          trimmed == 'Things to Watch Out For') {
        widgets.add(pw.Text(
          trimmed,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ));
        widgets.add(pw.SizedBox(height: 12));
      }
      else if (trimmed.startsWith('Patient ID:') ||
          trimmed.startsWith('Name:') ||
          trimmed.startsWith('Gender:') ||
          trimmed.startsWith('Age:')) {
        widgets.add(pw.Text(
          line,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            fontStyle: pw.FontStyle.italic,
          ),
        ));
      }
      else if (widgets.isNotEmpty &&
          widgets.last is pw.Text) {
        final lastPwText = widgets.last as pw.Text;
        final plainText = lastPwText.text.toPlainText();
        if (plainText.contains('Potential Diseases') &&
          trimmed.isNotEmpty &&
          !trimmed.contains(':')) {
          widgets.add(pw.Text(
            trimmed,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.orange800,
            ),
          ));
        } else {
          widgets.add(pw.Text(line, style: const pw.TextStyle(fontSize: 12)));
          widgets.add(pw.SizedBox(height: 6));
        }
      }
      else {
        widgets.add(pw.Text(line, style: const pw.TextStyle(fontSize: 12)));
        widgets.add(pw.SizedBox(height: 6));
      }
    }

    return widgets;
  }

  Future<void> _performAIAnalysis(List<Visit> visits) async {
    setState(() {
      _isLoadingAnalysis = true;
      _aiAnalysisResult = null;
    });

    try {
      Map<String, List<VisitNote>> detailedNotesMap = {};
      for (var visit in visits) {
        if (visit.id != null) {
          detailedNotesMap[visit.id!] = await DatabaseHelper().getVisitNotesForVisit(visit.id!);
        }
      }

      final analysis = await OpenRouterService().getMedicalAnalysis(
        patient: widget.patient,
        visits: visits,
        detailedNotesMap: detailedNotesMap,
      );

      setState(() => _aiAnalysisResult = analysis);

      _showAIAnalysisDialog(analysis);
    } catch (e) {
      String error = 'Error: ${e.toString()}';
      setState(() => _aiAnalysisResult = error);
      _showAIAnalysisDialog(error);
    } finally {
      setState(() => _isLoadingAnalysis = false);
    }
  }

  void _showAIAnalysisDialog(String analysisText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'AI Medical Analysis Report',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: _buildRichAnalysis(analysisText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _printAIAnalysisReport(analysisText);
            },
            child: const Text('Print Report'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _printAIAnalysisReport(String analysisText) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'AI Medical Analysis Report',
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Patient: ${widget.patient.displayId} • ID: ${widget.patient.id}',
              style: const pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 30),
          ..._buildPdfRichAnalysis(analysisText),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  Future<void> _printVisitHistory(List<Visit> visits) async {
    final doc = pw.Document();

    // Pre-fetch all detailed notes
    Map<String, List<VisitNote>> detailedNotesMap = {};
    for (var visit in visits) {
      if (visit.id != null) {
        detailedNotesMap[visit.id!] =
        await DatabaseHelper().getVisitNotesForVisit(visit.id!);
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Patient Visit History',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Patient ID: ${widget.patient.displayId}',
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(color: PdfColors.blue200, thickness: 1.5),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),

            // Visits - STACKED VERTICALLY
            for (var visit in visits) ...[
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                padding: const pw.EdgeInsets.all(16),
                margin: const pw.EdgeInsets.only(bottom: 14),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Date & Time Header
                    pw.Container(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.blue200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            formatDate(visit.visitDate),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            children: [
                              pw.Text(
                                formatTime(visit.visitDate),
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.SizedBox(width: 12),
                              pw.Text(
                                'CHW: ${visit.chwId}',
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // General Notes Section
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'General Notes:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            visit.notes != null && visit.notes!.isNotEmpty
                                ? _cleanTextForPdf(visit.notes!)
                                : 'No general notes recorded.',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: visit.notes != null && visit.notes!.isNotEmpty
                                  ? PdfColors.black
                                  : PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // Detailed Notes Section
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Detailed Notes:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          if (detailedNotesMap.containsKey(visit.id) &&
                              detailedNotesMap[visit.id]!.isNotEmpty)
                            ...detailedNotesMap[visit.id]!.map(
                                  (note) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 6),
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      width: 5,
                                      height: 5,
                                      margin: const pw.EdgeInsets.only(top: 5, right: 8),
                                      decoration: const pw.BoxDecoration(
                                        color: PdfColors.blue400,
                                        shape: pw.BoxShape.circle,
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        '${formatDate(note.timestamp)} at ${formatTime(note.timestamp)}: ${_cleanTextForPdf(note.content)}',
                                        style: const pw.TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            pw.Text(
                              'No detailed notes recorded.',
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Visit History – ${widget.patient.displayId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 1,
        actions: [
          // Show visit count badge
          FutureBuilder<List<Visit>>(
            future: _visitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${snapshot.data!.length} ${snapshot.data!.length == 1 ? 'Visit' : 'Visits'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          FutureBuilder<List<Visit>>(
            future: _visitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data!.isNotEmpty) {
                return _isLoadingAnalysis
                    ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : IconButton(
                  icon: Icon(
                    _aiAnalysisResult != null 
                      ? Icons.psychology 
                      : Icons.psychology_outlined,
                    color: _aiAnalysisResult != null ? Colors.amber : Colors.white,
                  ),
                  onPressed: () {
                    if (_aiAnalysisResult != null) {
                      _showAIAnalysisDialog(_aiAnalysisResult!);
                    } else {
                      _performAIAnalysis(snapshot.data!);
                    }
                  },
                  tooltip: _aiAnalysisResult != null 
                      ? 'View AI Analysis' 
                      : 'Get AI Analysis',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          FutureBuilder<List<Visit>>(
            future: _visitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data!.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => _printVisitHistory(snapshot.data!),
                  tooltip: 'Print Visit History',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Visit>>(
        future: _visitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No visit history found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final visits = snapshot.data!;

          return Column(
            children: [
              // Statistics header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildVisitStatCard(
                      'Total Visits',
                      visits.length.toString(),
                      Icons.medical_services,
                      Colors.blue,
                    ),
                    _buildVisitStatCard(
                      'Latest Visit',
                      visits.isNotEmpty ? formatDate(visits.first.visitDate) : 'N/A',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    final visit = visits[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            spreadRadius: 1,
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child:
                            const Icon(Icons.calendar_month, color: Colors.blue),
                          ),
                          title: Text(
                            formatDate(visit.visitDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "CHW: ${visit.chwId}",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "Time: ${formatTime(visit.visitDate)}",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (visit.notes != null && visit.notes!.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "General Notes",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      visit.notes!,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ),
                            FutureBuilder<List<VisitNote>>(
                              future:
                              DatabaseHelper().getVisitNotesForVisit(visit.id!),
                              builder: (context, noteSnapshot) {
                                if (noteSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (noteSnapshot.hasError) {
                                  return Text(
                                      'Error loading notes: ${noteSnapshot.error}',
                                      style: const TextStyle(color: Colors.red));
                                }
                                if (!noteSnapshot.hasData ||
                                    noteSnapshot.data!.isEmpty) {
                                  return const Text(
                                    'No detailed notes.',
                                    style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                                  );
                                }

                                final notes = noteSnapshot.data!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Detailed Notes",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...notes.map(
                                          (note) => Container(
                                        margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.note_alt_outlined,
                                                color: Colors.blue, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${formatDate(note.timestamp)} at ${formatTime(note.timestamp)}",
                                                    style: TextStyle(
                                                      color: Colors.blue.shade700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    note.content,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVisitStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _cleanTextForPdf(String content) => content;
}