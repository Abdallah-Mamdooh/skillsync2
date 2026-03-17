const cron = require('node-cron');
const mentorSessionService = require('./mentorSession.service');

function startMentorSessionCron() {
  cron.schedule('* * * * *', async () => {
    try {
      await mentorSessionService.runLifecycleSweep();
    } catch (error) {
      console.error('Mentor session cron error:', error.message);
    }
  });
}

module.exports = {
  startMentorSessionCron,
};