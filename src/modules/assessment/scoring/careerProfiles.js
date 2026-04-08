function norm(name) {
  return String(name || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

/**
 * Personality:
 * EI -> E / I
 * SN -> S / N
 * TF -> T / F
 * JP -> J / P
 *
 * Soft skill categories MUST match seeded question categories:
 * - communication
 * - teamwork
 * - adaptability
 * - problem_solving
 * - leadership
 * - self_management
 */
const PROFILES_BY_NAME = {
  // ---------------- WEB / SOFTWARE ----------------
  [norm('Frontend')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 3,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 1,
    },
  },
  [norm('Frontend Beginner')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 3,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 1,
    },
  },
  [norm('Frontend Developer')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 3,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 1,
    },
  },

  [norm('Backend')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 1,
      problem_solving: 4,
      leadership: 1,
      self_management: 3,
    },
  },
  [norm('Backend Beginner')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 1,
      problem_solving: 4,
      leadership: 1,
      self_management: 3,
    },
  },
  [norm('Backend Developer')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 1,
      problem_solving: 4,
      leadership: 1,
      self_management: 3,
    },
  },

  [norm('Full Stack')]: {
    personality: { EI: 'E', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('React')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 3,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 1,
    },
  },

  [norm('Angular')]: {
    personality: { EI: 'E', SN: 'N', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Vue')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 3,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 1,
    },
  },

  [norm('Nodejs')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 1,
      problem_solving: 4,
      leadership: 1,
      self_management: 3,
    },
  },

  [norm('Javascript')]: {
    personality: { EI: 'E', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Typescript')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },

  // ---------------- DATA / AI ----------------
  [norm('Data Analyst')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 1,
      adaptability: 2,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Data Engineer')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Machine Learning')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Mlops')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Ai Engineer')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Ai Data Scientist')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },

  [norm('Ai Agents')]: {
    personality: { EI: 'N', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },

  // ---------------- DEVOPS / INFRA ----------------
  [norm('Devops')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Devops Beginner')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Cloudflare')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Kubernetes')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Terraform')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },

  // ---------------- SECURITY ----------------
  [norm('Cyber Security')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Ai Red Teaming')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },

  // ---------------- QA ----------------
  [norm('Qa')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 1,
      problem_solving: 3,
      leadership: 1,
      self_management: 3,
    },
  },

  // ---------------- DESIGN ----------------
  [norm('Ux Design')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 4,
      teamwork: 3,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 1,
    },
  },
  [norm('Design System')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'J' },
    softWeights: {
      communication: 3,
      teamwork: 3,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 2,
    },
  },

  // ---------------- PRODUCT ----------------
  [norm('Product Manager')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'J' },
    softWeights: {
      communication: 4,
      teamwork: 3,
      adaptability: 2,
      problem_solving: 2,
      leadership: 3,
      self_management: 2,
    },
  },

  // ---------------- ARCHITECTURE ----------------
  [norm('Software Architect')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 2,
      self_management: 2,
    },
  },
  [norm('System Design')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 4,
      leadership: 2,
      self_management: 2,
    },
  },

  // ---------------- MOBILE / GAME ----------------
  [norm('Flutter')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Android')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Ios')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'J' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('React Native')]: {
    personality: { EI: 'E', SN: 'N', TF: 'F', JP: 'P' },
    softWeights: {
      communication: 2,
      teamwork: 2,
      adaptability: 2,
      problem_solving: 2,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Game Developer')]: {
    personality: { EI: 'I', SN: 'N', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 3,
      leadership: 1,
      self_management: 2,
    },
  },
  [norm('Server Side Game Developer')]: {
    personality: { EI: 'I', SN: 'S', TF: 'T', JP: 'P' },
    softWeights: {
      communication: 1,
      teamwork: 2,
      adaptability: 3,
      problem_solving: 4,
      leadership: 1,
      self_management: 2,
    },
  },
};

function getCareerProfileByName(careerName) {
  return PROFILES_BY_NAME[norm(careerName)] || null;
}

module.exports = {
  getCareerProfileByName,
};