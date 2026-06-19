const path = require('path');
const fs = require('fs');
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');
const CvAnalysisResult = require('./cvAnalysis.model');

function ensureFileExists(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    throw new Error('Uploaded CV file was not found');
  }
}

function normalizeArray(value) {
  return Array.isArray(value) ? value : [];
}

function cleanText(text = '') {
  return String(text)
    .replace(/\r/g, '\n')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

async function extractTextFromCv(filePath, originalFileName = '') {
  ensureFileExists(filePath);

  const ext = path.extname(originalFileName || filePath).toLowerCase();
  const buffer = fs.readFileSync(filePath);

  if (ext === '.pdf') {
    const data = await pdfParse(buffer);
    return cleanText(data.text || '');
  }

  if (ext === '.docx') {
    const data = await mammoth.extractRawText({ path: filePath });
    return cleanText(data.value || '');
  }

  throw new Error('Unsupported CV file type. Please upload PDF or DOCX.');
}

function countWords(text = '') {
  const words = text.match(/\b[\w+#.-]+\b/g);
  return words ? words.length : 0;
}

function containsAny(text, keywords = []) {
  return keywords.some((keyword) => text.includes(keyword));
}

function unique(values = []) {
  return [...new Set(values.filter(Boolean))];
}

function detectField(lowerText, detectedFieldOverride = '') {
  if (detectedFieldOverride) {
    return detectedFieldOverride;
  }

  const fields = [
    {
      name: 'Software Development',
      keywords: ['javascript', 'node', 'express', 'react', 'flutter', 'dart', 'api', 'mongodb', 'sql', 'frontend', 'backend'],
    },
    {
      name: 'Data Science',
      keywords: ['python', 'pandas', 'numpy', 'machine learning', 'data analysis', 'model', 'classification', 'regression'],
    },
    {
      name: 'Quality Control / Testing',
      keywords: ['testing', 'test cases', 'bug', 'qa', 'qc', 'selenium', 'postman', 'api testing', 'manual testing'],
    },
    {
      name: 'UI/UX Design',
      keywords: ['figma', 'wireframe', 'prototype', 'user experience', 'ui', 'ux'],
    },
    {
      name: 'Digital Marketing',
      keywords: ['marketing', 'seo', 'social media', 'campaign', 'content', 'analytics'],
    },
  ];

  let bestField = 'General';
  let bestScore = 0;

  fields.forEach((field) => {
    const score = field.keywords.filter((keyword) => lowerText.includes(keyword)).length;
    if (score > bestScore) {
      bestScore = score;
      bestField = field.name;
    }
  });

  return bestField;
}

function analyzeCvText({ text, detectedFieldOverride = '', jobDescription = '' }) {
  const lowerText = text.toLowerCase();
  const lowerJd = String(jobDescription || '').toLowerCase();
  const wordCount = countWords(text);

  const sections = {
    contact: containsAny(lowerText, ['email', '@', 'phone', 'mobile', 'linkedin', 'github']),
    summary: containsAny(lowerText, ['summary', 'profile', 'objective', 'about me']),
    education: containsAny(lowerText, ['education', 'university', 'college', 'faculty', 'bachelor', 'degree', 'graduation']),
    experience: containsAny(lowerText, ['experience', 'internship', 'employment', 'work experience', 'responsibilities']),
    skills: containsAny(lowerText, ['skills', 'technical skills', 'soft skills', 'tools', 'technologies']),
    projects: containsAny(lowerText, ['projects', 'graduation project', 'portfolio']),
    achievements: containsAny(lowerText, ['achievement', 'award', 'competition', 'certification', 'certificate']),
  };

  const skillKeywords = [
    'javascript',
    'typescript',
    'react',
    'node',
    'express',
    'mongodb',
    'mysql',
    'sql',
    'flutter',
    'dart',
    'python',
    'java',
    'c++',
    'html',
    'css',
    'git',
    'github',
    'api',
    'rest',
    'postman',
    'testing',
    'test cases',
    'selenium',
    'figma',
    'firebase',
    'railway',
    'docker',
  ];

  const detectedSkills = unique(
    skillKeywords.filter((skill) => lowerText.includes(skill))
  );

  const missingSections = Object.entries(sections)
    .filter(([, exists]) => !exists)
    .map(([section]) => section);

  const strongPoints = [];
  const quickWins = [];
  const atsIssues = [];
  const writingIssues = [];
  const improvements = [];

  if (sections.skills && detectedSkills.length >= 5) {
    strongPoints.push('The CV includes a clear set of technical keywords and skills.');
  }

  if (sections.projects) {
    strongPoints.push('The CV includes project experience, which helps demonstrate practical ability.');
  }

  if (sections.education) {
    strongPoints.push('The CV includes education information.');
  }

  if (sections.experience) {
    strongPoints.push('The CV includes experience or internship-related content.');
  }

  if (!sections.contact) {
    atsIssues.push('Missing clear contact information such as email, phone, LinkedIn, or GitHub.');
    quickWins.push('Add contact information at the top of the CV.');
  }

  if (!sections.summary) {
    improvements.push('Add a short professional summary at the beginning of the CV.');
  }

  if (!sections.education) {
    improvements.push('Add an education section with university, degree, and graduation year.');
  }

  if (!sections.experience) {
    improvements.push('Add internships, training, freelance work, or practical experience.');
  }

  if (!sections.skills) {
    atsIssues.push('Missing a clear skills section.');
    quickWins.push('Add a dedicated skills section with tools and technologies.');
  }

  if (!sections.projects) {
    improvements.push('Add a projects section with project name, technologies, and your role.');
  }

  if (detectedSkills.length < 4) {
    atsIssues.push('The CV has too few technical keywords for ATS matching.');
    quickWins.push('Add more relevant technical keywords that match the target role.');
  }

  if (wordCount < 250) {
    writingIssues.push('The CV looks too short and may not provide enough detail.');
    improvements.push('Add more details about responsibilities, achievements, tools, and project outcomes.');
  }

  if (wordCount > 1200) {
    writingIssues.push('The CV may be too long. Try to keep it focused and easy to scan.');
  }

  if (!/\d/.test(text)) {
    writingIssues.push('The CV does not show measurable achievements or numbers.');
    quickWins.push('Add measurable results such as percentages, counts, rankings, or project impact.');
  }

  let score = 35;

  if (sections.contact) score += 8;
  if (sections.summary) score += 7;
  if (sections.education) score += 8;
  if (sections.experience) score += 10;
  if (sections.skills) score += 10;
  if (sections.projects) score += 10;
  if (sections.achievements) score += 5;

  if (detectedSkills.length >= 8) score += 10;
  else if (detectedSkills.length >= 5) score += 7;
  else if (detectedSkills.length >= 3) score += 4;

  if (wordCount >= 350 && wordCount <= 900) score += 7;
  else if (wordCount >= 250) score += 4;

  if (/\d/.test(text)) score += 5;

  score = Math.max(0, Math.min(score, 100));

  let grade = 'Needs Improvement';
  if (score >= 85) grade = 'Excellent';
  else if (score >= 70) grade = 'Good';
  else if (score >= 55) grade = 'Fair';

  let jdMatchScore = null;
  let missingKeywords = [];

  if (lowerJd) {
    const jdWords = unique(
      lowerJd
        .match(/\b[a-zA-Z][a-zA-Z+#.-]{2,}\b/g)
        ?.filter((word) => !['the', 'and', 'for', 'with', 'you', 'are', 'this', 'that', 'from', 'will', 'have', 'has'].includes(word)) || []
    );

    const matched = jdWords.filter((word) => lowerText.includes(word));
    missingKeywords = jdWords.filter((word) => !lowerText.includes(word)).slice(0, 15);

    jdMatchScore = jdWords.length
      ? Math.round((matched.length / jdWords.length) * 100)
      : null;
  }

  const detectedField = detectField(lowerText, detectedFieldOverride);

  const summary =
    score >= 70
      ? 'The CV is generally well structured, but it can still be improved with stronger keywords and clearer achievements.'
      : 'The CV needs improvement in structure, ATS keywords, and content depth to better match career opportunities.';

  return {
    score,
    grade,
    word_count: wordCount,
    detected_field: detectedField,
    summary,
    strong_points: normalizeArray(strongPoints),
    quick_wins: normalizeArray(quickWins),
    missing_sections: normalizeArray(missingSections),
    ats_issues: normalizeArray(atsIssues),
    writing_issues: normalizeArray(writingIssues),
    improvements: normalizeArray(improvements),
    jd_match_score: jdMatchScore,
    missing_keywords: normalizeArray(missingKeywords),
    detected_skills: normalizeArray(detectedSkills),
    provider: 'node_internal_cv_analyzer',
  };
}

function normalizeAnalysisResponse(data = {}) {
  return {
    score: Number(data.score || 0),
    grade: String(data.grade || ''),
    wordCount: Number(data.word_count || 0),
    detectedField: String(data.detected_field || ''),
    summary: String(data.summary || ''),
    strongPoints: normalizeArray(data.strong_points),
    quickWins: normalizeArray(data.quick_wins),
    missingSections: normalizeArray(data.missing_sections),
    atsIssues: normalizeArray(data.ats_issues),
    writingIssues: normalizeArray(data.writing_issues),
    improvements: normalizeArray(data.improvements),
    jdMatchScore:
      data.jd_match_score === undefined || data.jd_match_score === null
        ? null
        : Number(data.jd_match_score),
    missingKeywords: normalizeArray(data.missing_keywords),
    rawResponse: data,
  };
}

async function analyzeCv({
  userId,
  file,
  cvUrl = '',
  detectedFieldOverride = '',
  jobDescription = '',
}) {
  if (!userId) {
    throw new Error('userId is required');
  }

  if (!file) {
    throw new Error('CV file is required');
  }

  const filePath = file.path || '';
  const originalFileName = file.originalname || path.basename(filePath);

  const extractedText = await extractTextFromCv(filePath, originalFileName);

  if (!extractedText || extractedText.length < 50) {
    throw new Error('Could not extract enough text from the CV. Please upload a clear PDF or DOCX file.');
  }

  const analysisResult = analyzeCvText({
    text: extractedText,
    detectedFieldOverride,
    jobDescription,
  });

  const normalized = normalizeAnalysisResponse(analysisResult);

  const saved = await CvAnalysisResult.create({
    userId,
    cvUrl,
    originalFileName,
    detectedField: normalized.detectedField,
    score: normalized.score,
    grade: normalized.grade,
    wordCount: normalized.wordCount,
    summary: normalized.summary,
    strongPoints: normalized.strongPoints,
    quickWins: normalized.quickWins,
    missingSections: normalized.missingSections,
    atsIssues: normalized.atsIssues,
    writingIssues: normalized.writingIssues,
    improvements: normalized.improvements,
    jdMatchScore: normalized.jdMatchScore,
    missingKeywords: normalized.missingKeywords,
    analysisProvider: 'node_internal_cv_analyzer',
    rawResponse: normalized.rawResponse,
  });

  return saved;
}

async function getLatestAnalysis(userId) {
  const latest = await CvAnalysisResult.findOne({ userId }).sort({
    createdAt: -1,
  });

  if (!latest) {
    return null;
  }

  return latest;
}

async function getMyAnalysisHistory(userId) {
  return CvAnalysisResult.find({ userId }).sort({ createdAt: -1 });
}

module.exports = {
  analyzeCv,
  getLatestAnalysis,
  getMyAnalysisHistory,
};