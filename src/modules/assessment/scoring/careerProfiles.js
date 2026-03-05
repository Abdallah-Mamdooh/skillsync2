// careerProfiles.js
// Maps "career name" -> expected traits.
// We match using normalized name (lowercase).

function norm(name) {
  return String(name || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

/**
 * Personality preference means: which pole is preferred in each MBTI dimension.
 * EI: 'E' or 'I'
 * SN: 'S' or 'N'
 * TF: 'T' or 'F'
 * JP: 'J' or 'P'
 *
 * softWeights indicates importance of soft categories (sum doesn't need to be 1, we normalize)
 */
const PROFILES_BY_NAME = {
  // Web
  [norm('Frontend')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 2, problemSolving: 2, leadership: 1, timeManagement: 1 },
  },
  [norm('Frontend Beginner')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 2, problemSolving: 2, leadership: 1, timeManagement: 1 },
  },
  [norm('Backend')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 1, problemSolving: 3, leadership: 1, timeManagement: 2 },
  },
  [norm('Backend Beginner')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 1, problemSolving: 3, leadership: 1, timeManagement: 2 },
  },
  [norm('Full Stack')]: {
    personality: { EI: 'E', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 3, problemSolving: 3, leadership: 1, timeManagement: 2 },
  },

  // Data / AI
  [norm('Data Engineer')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: { communication: 1, teamwork: 2, adaptability: 2, problemSolving: 4, leadership: 1, timeManagement: 2 },
  },
  [norm('Machine Learning')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: { communication: 1, teamwork: 2, adaptability: 2, problemSolving: 4, leadership: 1, timeManagement: 2 },
  },
  [norm('Mlops')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 3, problemSolving: 3, leadership: 1, timeManagement: 2 },
  },

  // DevOps / Infra
  [norm('Devops')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'P' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 3, problemSolving: 3, leadership: 1, timeManagement: 2 },
  },
  [norm('Devops Beginner')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'P' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 3, problemSolving: 3, leadership: 1, timeManagement: 2 },
  },

  // Security
  [norm('Cyber Security')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: { communication: 1, teamwork: 2, adaptability: 2, problemSolving: 4, leadership: 1, timeManagement: 2, conflictManagement: 2 },
  },

  // QA
  [norm('Qa')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 1, problemSolving: 3, leadership: 1, timeManagement: 3 },
  },

  // Design
  [norm('Ux Design')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: { communication: 4, teamwork: 3, adaptability: 2, problemSolving: 2, leadership: 1, timeManagement: 1 },
  },

  // Product
  [norm('Product Manager')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'J' },
    softWeights: { communication: 4, teamwork: 3, adaptability: 2, problemSolving: 2, leadership: 3, timeManagement: 2, conflictManagement: 3 },
  },

  // Architecture
  [norm('Software Architect')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'J' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 2, problemSolving: 4, leadership: 2, timeManagement: 2 },
  },
  [norm('System Design')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'J' },
    softWeights: { communication: 2, teamwork: 2, adaptability: 2, problemSolving: 4, leadership: 2, timeManagement: 2 },
  },
};

function getCareerProfileByName(careerName) {
  return PROFILES_BY_NAME[norm(careerName)] || null;
}

module.exports = {
  getCareerProfileByName,
};