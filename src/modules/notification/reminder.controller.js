const asyncHandler = require('../../middlewares/async.middleware');
const reminderService = require('./reminder.service');

const runReminderChecks = asyncHandler(async (req, res) => {
  const data = await reminderService.runReminderChecks();

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  runReminderChecks,
};