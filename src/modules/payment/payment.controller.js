const asyncHandler = require('../../middlewares/async.middleware');
const paymentService = require('./payment.service');
const User = require('../auth/user.model');
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

const createFawryCheckout = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).select(
    'fullName email phoneNumber'
  );

  if (!user) {
    throw new Error('User not found');
  }

  const data = await paymentService.createFawryCheckout({
    user: {
      _id: req.user._id,
      fullName: user.fullName,
      email: user.email,
      phoneNumber: user.phoneNumber,
    },
    amount: req.body.amount,
    purpose: 'deposit',
    entityType: 'wallet_topup',
    entityId: null,
    description: req.body.description || 'Wallet top-up via Fawry',
    paymentMethod: req.body.paymentMethod || '',
  });

  res.status(200).json({
    success: true,
    data,
  });
});
module.exports = {
  addPaymentMethod,
  listPaymentMethods,
  depositToWallet,
  getWalletSummary,
  createFawryCheckout,
};