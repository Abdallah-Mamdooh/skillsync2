require('dotenv').config();
const mongoose = require('mongoose');
const AssessmentSection = require('../src/modules/assessment/assessmentSection.model');
const Question = require('../src/modules/assessment/question.model');

// ---- DB connect (same style as your other scripts) ----
async function connectDB() {
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  if (!uri) throw new Error('Missing MONGO_URI (or MONGODB_URI) in .env');

  await mongoose.connect(uri);
  console.log('MongoDB connected');
}

function makeMCQ({ sectionId, category, questionCode, text, options, meta }) {
  return {
    sectionId,
    category,
    questionCode,
    text,
    answerType: 'single',
    options: options.map((o, idx) => ({
      key: String.fromCharCode(65 + idx), // A,B,C,D
      text: o.text,
      isCorrect: !!o.isCorrect,
      careerWeights: [], // keep empty for MVP
    })),
    meta,
  };
}

async function upsertQuestion(doc) {
  await Question.updateOne(
    { questionCode: doc.questionCode },
    { $set: doc },
    { upsert: true }
  );
}

// -------------------- Question Bank --------------------

// ✅ Core (base) = not specialty
const CORE_19 = [
  // Core CS (5)
  {
    questionCode: 'T33',
    text: 'Big-O notation is used to measure:',
    options: [
      { text: 'Code readability' },
      { text: 'Algorithm efficiency', isCorrect: true },
      { text: 'UI responsiveness' },
      { text: 'Server uptime' },
    ],
  },
  {
    questionCode: 'T34',
    text: 'A primary key ensures:',
    options: [
      { text: 'Fast sorting' },
      { text: 'Unique identification', isCorrect: true },
      { text: 'Data backup' },
      { text: 'Encryption' },
    ],
  },
  {
    questionCode: 'T35',
    text: 'REST APIs commonly use:',
    options: [
      { text: 'SMTP' },
      { text: 'FTP' },
      { text: 'HTTP', isCorrect: true },
      { text: 'SSH' },
    ],
  },
  {
    questionCode: 'T36',
    text: 'Recursion refers to:',
    options: [
      { text: 'Nested loops' },
      { text: 'A function calling itself', isCorrect: true },
      { text: 'Parallel processing' },
      { text: 'Database indexing' },
    ],
  },
  {
    questionCode: 'T37',
    text: 'An API is:',
    options: [
      { text: 'A user interface' },
      { text: 'A communication interface between systems', isCorrect: true },
      { text: 'A database engine' },
      { text: 'A programming language' },
    ],
  },

  // Frontend foundations (4)
  {
    questionCode: 'T38',
    text: 'The DOM represents:',
    options: [
      { text: 'Database Object Model' },
      { text: 'Document Object Model', isCorrect: true },
      { text: 'Data Operation Mode' },
      { text: 'Design Object Mapping' },
    ],
  },
  {
    questionCode: 'T39',
    text: 'CSS Flexbox is primarily used for:',
    options: [
      { text: 'Animations' },
      { text: 'Layout alignment', isCorrect: true },
      { text: 'Security' },
      { text: 'Backend routing' },
    ],
  },
  {
    questionCode: 'T40',
    text: 'Media queries are used for:',
    options: [
      { text: 'Security rules' },
      { text: 'Responsive design', isCorrect: true },
      { text: 'Database queries' },
      { text: 'API calls' },
    ],
  },
  {
    questionCode: 'T41',
    text: 'Accessibility (a11y) ensures:',
    options: [
      { text: 'Fast loading' },
      { text: 'Usability for all users', isCorrect: true },
      { text: 'SEO ranking' },
      { text: 'Encryption' },
    ],
  },

  // Backend foundations (5)
  {
    questionCode: 'T42',
    text: 'Middleware is used to:',
    options: [
      { text: 'Design UI' },
      { text: 'Process requests between client and server', isCorrect: true },
      { text: 'Store passwords' },
      { text: 'Compile code' },
    ],
  },
  {
    questionCode: 'T43',
    text: 'JWT is used for:',
    options: [
      { text: 'Styling' },
      { text: 'Authentication', isCorrect: true },
      { text: 'Logging' },
      { text: 'Caching' },
    ],
  },
  {
    questionCode: 'T44',
    text: 'ACID properties relate to:',
    options: [
      { text: 'Networking' },
      { text: 'Database transactions', isCorrect: true },
      { text: 'UI components' },
      { text: 'Encryption' },
    ],
  },
  {
    questionCode: 'T45',
    text: 'Caching improves:',
    options: [
      { text: 'Security' },
      { text: 'Performance', isCorrect: true },
      { text: 'Compilation' },
      { text: 'Logging' },
    ],
  },
  {
    questionCode: 'T46',
    text: 'Microservices architecture divides systems into:',
    options: [
      { text: 'UI components' },
      { text: 'Independent services', isCorrect: true },
      { text: 'Single database' },
      { text: 'Static files' },
    ],
  },

  // Data/AI foundations (5)
  {
    questionCode: 'T47',
    text: 'Overfitting occurs when:',
    options: [
      { text: 'Model generalizes well' },
      { text: 'Model memorizes training data', isCorrect: true },
      { text: 'Data is clean' },
      { text: 'Algorithm fails' },
    ],
  },
  {
    questionCode: 'T48',
    text: 'Regression is used for:',
    options: [
      { text: 'Classification' },
      { text: 'Predicting continuous values', isCorrect: true },
      { text: 'Clustering' },
      { text: 'Encryption' },
    ],
  },
  {
    questionCode: 'T49',
    text: 'Cross-validation is used to:',
    options: [
      { text: 'Increase dataset' },
      { text: 'Validate model performance', isCorrect: true },
      { text: 'Remove bias' },
      { text: 'Encrypt data' },
    ],
  },
  {
    questionCode: 'T50',
    text: 'SQL JOIN is used to:',
    options: [
      { text: 'Delete records' },
      { text: 'Combine tables', isCorrect: true },
      { text: 'Encrypt database' },
      { text: 'Sort data' },
    ],
  },
  {
    questionCode: 'T51',
    text: 'Standard deviation measures:',
    options: [
      { text: 'Accuracy' },
      { text: 'Data spread', isCorrect: true },
      { text: 'Median' },
      { text: 'Mode' },
    ],
  },
];

// ✅ Specialty packs (3 per interest)
// We set meta.technical.area = concept | tool | applied
const SPECIALTY_PACKS = [
  // web
  {
    questionCode: 'TS-WEB-1',
    interest: 'web',
    area: 'concept',
    text: 'What does the DOM represent?',
    options: [
      { text: 'Database Object Model' },
      { text: 'Document Object Model', isCorrect: true },
      { text: 'Data Operation Mode' },
      { text: 'Design Object Mapping' },
    ],
  },
  {
    questionCode: 'TS-WEB-2',
    interest: 'web',
    area: 'tool',
    text: 'CSS Flexbox is primarily used for:',
    options: [
      { text: 'Animations' },
      { text: 'Layout alignment', isCorrect: true },
      { text: 'Security' },
      { text: 'Backend routing' },
    ],
  },
  {
    questionCode: 'TS-WEB-3',
    interest: 'web',
    area: 'applied',
    text: 'Media queries are mainly used to:',
    options: [
      { text: 'Secure APIs' },
      { text: 'Build responsive layouts for different screen sizes', isCorrect: true },
      { text: 'Connect databases' },
      { text: 'Improve server-side caching' },
    ],
  },

  // data_ai
  {
    questionCode: 'TS-DATAAI-1',
    interest: 'data_ai',
    area: 'concept',
    text: 'Overfitting occurs when:',
    options: [
      { text: 'A model generalizes well to unseen data' },
      { text: 'A model memorizes training data and performs poorly on new data', isCorrect: true },
      { text: 'The dataset is fully cleaned' },
      { text: 'The algorithm runs too slowly' },
    ],
  },
  {
    questionCode: 'TS-DATAAI-2',
    interest: 'data_ai',
    area: 'tool',
    text: 'SQL JOIN is used to:',
    options: [
      { text: 'Delete records permanently' },
      { text: 'Combine data from multiple tables', isCorrect: true },
      { text: 'Encrypt database tables' },
      { text: 'Sort numeric columns only' },
    ],
  },
  {
    questionCode: 'TS-DATAAI-3',
    interest: 'data_ai',
    area: 'applied',
    text: 'Cross-validation is mainly used to:',
    options: [
      { text: 'Increase dataset size' },
      { text: 'Evaluate how well a model may perform on unseen data', isCorrect: true },
      { text: 'Remove all bias from data' },
      { text: 'Replace test datasets completely' },
    ],
  },

  // security
  {
    questionCode: 'TS-SEC-1',
    interest: 'security',
    area: 'concept',
    text: 'Phishing is best described as:',
    options: [
      { text: 'A type of database indexing' },
      { text: 'A social engineering attack used to steal information', isCorrect: true },
      { text: 'A method for encrypting files' },
      { text: 'A browser rendering issue' },
    ],
  },
  {
    questionCode: 'TS-SEC-2',
    interest: 'security',
    area: 'tool',
    text: 'A firewall is primarily used to:',
    options: [
      { text: 'Create UI layouts' },
      { text: 'Filter and control network traffic', isCorrect: true },
      { text: 'Compress application files' },
      { text: 'Generate API documentation' },
    ],
  },
  {
    questionCode: 'TS-SEC-3',
    interest: 'security',
    area: 'applied',
    text: 'Penetration testing is performed to:',
    options: [
      { text: 'Improve visual design consistency' },
      { text: 'Identify vulnerabilities before attackers exploit them', isCorrect: true },
      { text: 'Increase server storage capacity' },
      { text: 'Replace monitoring systems' },
    ],
  },

  // design
  {
    questionCode: 'TS-DESIGN-1',
    interest: 'design',
    area: 'concept',
    text: 'A wireframe is:',
    options: [
      { text: 'A final high-fidelity user interface' },
      { text: 'A low-fidelity layout used to plan structure', isCorrect: true },
      { text: 'A database relationship diagram' },
      { text: 'A backend deployment plan' },
    ],
  },
  {
    questionCode: 'TS-DESIGN-2',
    interest: 'design',
    area: 'tool',
    text: 'Usability testing is used to evaluate:',
    options: [
      { text: 'Server uptime' },
      { text: 'How easily users can use a product/interface', isCorrect: true },
      { text: 'Encryption strength' },
      { text: 'Database performance' },
    ],
  },
  {
    questionCode: 'TS-DESIGN-3',
    interest: 'design',
    area: 'applied',
    text: 'A user journey map is mainly used to:',
    options: [
      { text: 'Track network packets' },
      { text: 'Visualize the user’s steps and experience across interactions', isCorrect: true },
      { text: 'Define API endpoints' },
      { text: 'Build CSS themes' },
    ],
  },

  // product
  {
    questionCode: 'TS-PROD-1',
    interest: 'product',
    area: 'concept',
    text: 'What does MVP stand for?',
    options: [
      { text: 'Most Valuable Process' },
      { text: 'Minimum Viable Product', isCorrect: true },
      { text: 'Main Version Prototype' },
      { text: 'Managed Value Platform' },
    ],
  },
  {
    questionCode: 'TS-PROD-2',
    interest: 'product',
    area: 'tool',
    text: 'User stories are primarily used to describe:',
    options: [
      { text: 'Database schema rules' },
      { text: 'User needs and functional requirements', isCorrect: true },
      { text: 'Backend server configurations' },
      { text: 'Code refactoring steps' },
    ],
  },
  {
    questionCode: 'TS-PROD-3',
    interest: 'product',
    area: 'applied',
    text: 'A/B testing is typically used to:',
    options: [
      { text: 'Compare two product versions to measure performance or user response', isCorrect: true },
      { text: 'Encrypt user data' },
      { text: 'Increase server memory' },
      { text: 'Merge database tables' },
    ],
  },

  // devops
  {
    questionCode: 'TS-DEVOPS-1',
    interest: 'devops',
    area: 'concept',
    text: 'Infrastructure as Code (IaC) means:',
    options: [
      { text: 'Designing UI components with code' },
      { text: 'Managing infrastructure using code/configuration files', isCorrect: true },
      { text: 'Writing database queries in JSON' },
      { text: 'Encrypting network traffic automatically' },
    ],
  },
  {
    questionCode: 'TS-DEVOPS-2',
    interest: 'devops',
    area: 'tool',
    text: 'Kubernetes is primarily used for:',
    options: [
      { text: 'UI testing' },
      { text: 'Container orchestration', isCorrect: true },
      { text: 'Spreadsheet analysis' },
      { text: 'Browser automation' },
    ],
  },
  {
    questionCode: 'TS-DEVOPS-3',
    interest: 'devops',
    area: 'applied',
    text: 'Blue-Green deployment is mainly used to:',
    options: [
      { text: 'Improve frontend color themes' },
      { text: 'Reduce downtime and deployment risk during releases', isCorrect: true },
      { text: 'Encrypt production logs' },
      { text: 'Replace monitoring tools' },
    ],
  },

  // qa
  {
    questionCode: 'TS-QA-1',
    interest: 'qa',
    area: 'concept',
    text: 'Unit testing is used to verify:',
    options: [
      { text: 'Entire end-to-end system behavior only' },
      { text: 'Individual functions/components in isolation', isCorrect: true },
      { text: 'UI colors and branding' },
      { text: 'Network bandwidth usage' },
    ],
  },
  {
    questionCode: 'TS-QA-2',
    interest: 'qa',
    area: 'tool',
    text: 'A test case usually includes:',
    options: [
      { text: 'Only a bug title' },
      { text: 'Steps, inputs, and expected results', isCorrect: true },
      { text: 'Server credentials' },
      { text: 'API encryption keys' },
    ],
  },
  {
    questionCode: 'TS-QA-3',
    interest: 'qa',
    area: 'applied',
    text: 'Regression testing is performed to:',
    options: [
      { text: 'Confirm existing features still work after changes', isCorrect: true },
      { text: 'Increase application speed' },
      { text: 'Create new UI layouts' },
      { text: 'Reduce database size' },
    ],
  },
];

async function main() {
  await connectDB();

  const technicalSection = await AssessmentSection.findOne({ title: 'Technical' });
  if (!technicalSection) {
    throw new Error('Technical section not found. Seed sections first.');
  }

  // ---- core 19 ----
  for (const q of CORE_19) {
    const doc = makeMCQ({
      sectionId: technicalSection._id,
      category: 'technical',
      questionCode: q.questionCode,
      text: q.text,
      options: q.options,
      meta: {
        technical: {
          isSpecialty: false,
          multiplier: 1,
        },
      },
    });

    await upsertQuestion(doc);
  }

  // ---- specialty packs ----
  for (const q of SPECIALTY_PACKS) {
    const doc = makeMCQ({
      sectionId: technicalSection._id,
      category: 'technical',
      questionCode: q.questionCode,
      text: q.text,
      options: q.options,
      meta: {
        technical: {
          isSpecialty: true,
          interest: q.interest,
          area: q.area, // concept | tool | applied
          multiplier: 1,
        },
      },
    });

    await upsertQuestion(doc);
  }

  console.log(`✅ Seeded technical questions: core=${CORE_19.length}, specialty=${SPECIALTY_PACKS.length}`);

  await mongoose.disconnect();
  console.log('MongoDB disconnected');
}

main().catch(async (err) => {
  console.error('❌ Seed technical questions failed:', err.message);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});