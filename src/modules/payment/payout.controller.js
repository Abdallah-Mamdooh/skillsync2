const asyncHandler = require('../../middlewares/async.middleware');
const payoutService = require('./payout.service');

const addPayoutMethod = asyncHandler(async (req, res) => {
  const data = await payoutService.addPayoutMethod(req.user._id, req.body);
  res.status(201).json({ success: true, data });
});

const listPayoutMethods = asyncHandler(async (req, res) => {
  const data = await payoutService.listPayoutMethods(req.user._id);
  res.status(200).json({ success: true, data });
});

const requestWithdrawal = asyncHandler(async (req, res) => {
  const data = await payoutService.requestWithdrawal(req.user._id, req.body);
  res.status(201).json({ success: true, data });
});

const listMyWithdrawalRequests = asyncHandler(async (req, res) => {
  const data = await payoutService.listMyWithdrawalRequests(req.user._id);
  res.status(200).json({ success: true, data });
});

const listAllWithdrawalRequests = asyncHandler(async (req, res) => {
  const data = await payoutService.listAllWithdrawalRequests(req.query);
  res.status(200).json({ success: true, data });
});

const approveWithdrawalRequest = asyncHandler(async (req, res) => {
  const data = await payoutService.approveWithdrawalRequest(
    req.params.withdrawalRequestId,
    req.user._id,
    req.body.adminNote || ''
  );
  res.status(200).json({ success: true, data });
});

const rejectWithdrawalRequest = asyncHandler(async (req, res) => {
  const data = await payoutService.rejectWithdrawalRequest(
    req.params.withdrawalRequestId,
    req.user._id,
    req.body.adminNote || ''
  );
  res.status(200).json({ success: true, data });
});

const markWithdrawalRequestPaid = asyncHandler(async (req, res) => {
  const data = await payoutService.markWithdrawalRequestPaid(
    req.params.withdrawalRequestId,
    req.user._id,
    req.body.payoutReference || '',
    req.body.adminNote || ''
  );
  res.status(200).json({ success: true, data });
});

const cancelMyWithdrawalRequest = asyncHandler(async (req, res) => {
  const data = await payoutService.cancelMyWithdrawalRequest(
    req.user._id,
    req.params.withdrawalRequestId
  );
  res.status(200).json({ success: true, data });
});

module.exports = {
  addPayoutMethod,
  listPayoutMethods,
  requestWithdrawal,
  listMyWithdrawalRequests,
  listAllWithdrawalRequests,
  approveWithdrawalRequest,
  rejectWithdrawalRequest,
  markWithdrawalRequestPaid,
  cancelMyWithdrawalRequest,
};