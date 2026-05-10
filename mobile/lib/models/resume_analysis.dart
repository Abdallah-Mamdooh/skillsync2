/// Data models for resume analysis API response

class ResumeAnalysis {
  final double score;
  final String grade;
  final int wordCount;
  final String detectedField;
  final String summary;
  final List<String> strongPoints;
  final List<String> quickWins;
  final List<String> missingSections;
  final List<String> atsIssues;
  final List<String> writingIssues;
  final List<String> improvements;
  final List<String> foundKeywords;
  final int? jdMatchScore;
  final List<String>? missingKeywords;

  ResumeAnalysis({
    required this.score,
    required this.grade,
    required this.wordCount,
    required this.detectedField,
    required this.summary,
    required this.strongPoints,
    required this.quickWins,
    required this.missingSections,
    required this.atsIssues,
    required this.writingIssues,
    required this.improvements,
    this.foundKeywords = const [],
    this.jdMatchScore,
    this.missingKeywords,
  });

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysis(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] ?? 'Unknown',
      wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
      detectedField: json['detected_field'] ?? 'Other',
      summary: json['summary'] ?? '',
      strongPoints: _stringList(json['strong_points']),
      quickWins: _stringList(json['quick_wins']),
      missingSections: _stringList(json['missing_sections']),
      atsIssues: _stringList(json['ats_issues']),
      writingIssues: _stringList(json['writing_issues']),
      improvements: _stringList(json['improvements']),
      foundKeywords: _stringList(json['keywords']),
      jdMatchScore: (json['jd_match_score'] as num?)?.toInt(),
      missingKeywords: json['missing_keywords'] != null
          ? _stringList(json['missing_keywords'])
          : null,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  String get scoreLabel {
    if (score == score.roundToDouble()) {
      return score.toStringAsFixed(0);
    }
    return score.toStringAsFixed(1);
  }

  String get gradeLabel => '$grade - $scoreLabel/100';

  bool get hasJDMatch => jdMatchScore != null;
}
