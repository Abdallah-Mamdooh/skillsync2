const cron = require('node-cron');
const reminderService = require('./reminder.service');

let remindersJobStarted = false;

const startReminderCron = () => {
  if (remindersJobStarted) return;

  remindersJobStarted = true;

  // Runs every 5 minutes
  cron.schedule('*/5 * * * *', async () => {
    try {
      const result = await reminderService.runReminderChecks();
      console.log('Reminder cron executed:', result);
    } catch (error) {
      console.error('Reminder cron failed:', error.message);
    }
  });

  console.log('Reminder cron started');
};

module.exports = {
  startReminderCron,
};