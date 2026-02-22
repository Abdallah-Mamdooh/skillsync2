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

app.use(notFound);
app.use(errorHandler);
app.use(express.json());


module.exports = app;
