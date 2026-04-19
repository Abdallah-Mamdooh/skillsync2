const path = require('path');
const fs = require('fs');
const axios = require('axios');
const FormData = require('form-data');
const CvAnalysisResult = require('./cvAnalysis.model');

const PYTHON_CV_ANALYZER_URL =
  process.env.PYTHON_CV_ANALYZER_URL || 'http://127.0.0.1:5001';

function ensureFileExists(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    throw new Error('Uploaded CV file was not found');
  }
}

function normalizeArray(value) {
  return Array.isArray(value) ? value : [];
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

async function callPythonCvAnalyzer({
  filePath,
  originalFileName,
  detectedFieldOverride = '',
  jobDescription = '',
}) {
  ensureFileExists(filePath);

  const form = new FormData();
  form.append('file', fs.createReadStream(filePath), originalFileName);

  if (detectedFieldOverride) {
    form.append('field', detectedFieldOverride);
  }

  if (jobDescription) {
    form.append('job_description', jobDescription);
  }

  try {
    const response = await axios.post(
      `${PYTHON_CV_ANALYZER_URL}/analyze`,
      form,
      {
        headers: {
          ...form.getHeaders(),
        },
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
      }
    );

    return response.data;
  } catch (error) {
    const pythonMessage =
      error?.response?.data?.error ||
      error?.response?.data?.message ||
      error.message ||
      'CV analysis failed';

    throw new Error(pythonMessage);
  }
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

  const pythonResult = await callPythonCvAnalyzer({
    filePath,
    originalFileName,
    detectedFieldOverride,
    jobDescription,
  });

  const normalized = normalizeAnalysisResponse(pythonResult);

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