const asyncHandler = require('../../middlewares/async.middleware');
const paymentService = require('./payment.service');

const addPaymentMethod = asyncHandler(async (req, res) => {
  const data = await paymentService.addPaymentMethod(req.user._id, req.body);
  res.status(201).json({ success: true, data });
});

const listPaymentMethods = asyncHandler(async (req, res) => {
  const data = await paymentService.listPaymentMethods(req.user._id);
  res.status(200).json({ success: true, data });
});

// MVP wallet top-up
const depositToWallet = asyncHandler(async (req, res) => {
  const data = await paymentService.depositToWallet(
    req.user._id,
    req.body.amount,
    req.body.notes
  );
  res.status(200).json({ success: true, data });
});

const getWalletSummary = asyncHandler(async (req, res) => {
  const data = await paymentService.getWalletSummary(req.user._id);
  res.status(200).json({ success: true, data });
});

module.exports = {
  addPaymentMethod,
  listPaymentMethods,
  depositToWallet,
  getWalletSummary,
};