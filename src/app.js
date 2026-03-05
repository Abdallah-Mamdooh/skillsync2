const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const routes = require('./routes');
const notFound = require('./middlewares/notFound.middleware');
const errorHandler = require('./middlewares/error.middleware');
const profileRoutes = require('./modules/profile/profile.routes');
const assessmentRoutes = require('./modules/assessment/assessment.routes');
const roadmapRoutes = require('./modules/roadmap/roadmap.routes');

const app = express();

app.use('/api/assessment', assessmentRoutes);


app.use('/api/roadmap', roadmapRoutes);

app.use('/api/profile', profileRoutes);

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/api', routes);

app.get('/debug/roadmap/:careerName', async (req, res) => {
  try {
    const Career = require('./modules/career/career.model');
    const Roadmap = require('./modules/roadmap/roadmap.model');

    const careerName = req.params.careerName.replace(/-/g, ' ');
    const career = await Career.findOne({ name: new RegExp(`^${careerName}$`, 'i') });

    if (!career) {
      return res.status(404).json({ error: `Career not found: ${req.params.careerName}` });
    }

    const roadmap = await Roadmap.findOne({ careerId: career._id });

    if (!roadmap) {
      return res.status(404).json({ error: `No roadmap found for career: ${career.name}` });
    }

    res.json({
      career: { id: career._id, name: career.name },
      phasesCount: roadmap.phases?.length || 0,
      stepsCount:
        roadmap.phases?.reduce((sum, p) => sum + (p.steps?.length || 0), 0) || 0,
      roadmap,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.get('/debug/careers', async (req, res) => {
  try {
const Career = require('./modules/career/career.model');    const careers = await Career.find({}, { name: 1 }).sort({ name: 1 }).limit(500);
    res.json({ count: careers.length, careers });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



app.use(notFound);
app.use(errorHandler);
app.use(express.json());


module.exports = app;
