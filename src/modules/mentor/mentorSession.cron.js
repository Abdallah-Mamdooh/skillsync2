const cron = require('node-cron');
const mentorSessionService = require('./mentorSession.service');
const mentorService = require('./mentor.service');

function startMentorSessionCron() {
  cron.schedule('* * * * *', async () => {
    try {
      await mentorSessionService.runLifecycleSweep();
      await mentorService.expireFinishedBreaks();
      await mentorService.applyApprovedScheduleChanges();
    } catch (error) {
      console.error('Mentor session cron error:', error.message);
    }
  });
}

module.exports = {
  startMentorSessionCron,
};