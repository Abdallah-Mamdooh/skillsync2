const asyncHandler = require('../../middlewares/async.middleware');
const paymentService = require('./payment.service');
const User = require('../auth/user.model');
const Transaction = require('./transaction.model');

const addPaymentMethod = asyncHandler(async (req, res) => {
  const data = await paymentService.addPaymentMethod(req.user._id, req.body);
  res.status(201).json({ success: true, data });
});

const listPaymentMethods = asyncHandler(async (req, res) => {
  const data = await paymentService.listPaymentMethods(req.user._id);
  res.status(200).json({ success: true, data });
});

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

const handleFawryWebhook = asyncHandler(async (req, res) => {
  const payload = req.body || {};

  const merchantRefNum =
    payload.merchantRefNumber ||
    payload.merchantRefNum ||
    payload.orderRefNum ||
    payload.referenceNumber ||
    '';

  const paymentStatus =
    payload.paymentStatus ||
    payload.orderStatus ||
    payload.status ||
    '';

  if (!merchantRefNum) {
    return res.status(400).json({
      success: false,
      message: 'merchantRefNum is missing',
    });
  }

  const transaction = await Transaction.findOne({
    $or: [{ providerReference: merchantRefNum }, { reference: merchantRefNum }],
    provider: 'fawry',
  });

  if (!transaction) {
    return res.status(404).json({
      success: false,
      message: 'Transaction not found',
    });
  }

  const normalizedStatus = String(paymentStatus || 'UNKNOWN').toUpperCase();
  transaction.providerStatus = normalizedStatus;

  if (payload.referenceNumber) {
    transaction.providerReference = String(payload.referenceNumber);
  }

  transaction.notes = transaction.notes || 'Fawry webhook received';
  transaction.rawProviderResponse = payload;

  if (['PAID', 'SUCCESS', 'COMPLETED'].includes(normalizedStatus)) {
    await transaction.save();
    await paymentService.applySuccessfulFawryTransaction(transaction);

    return res.status(200).json({
      success: true,
      message: 'Webhook processed successfully',
      status: normalizedStatus,
    });
  }

  if (['FAILED', 'CANCELLED', 'EXPIRED'].includes(normalizedStatus)) {
    await transaction.save();
    await paymentService.applyFailedFawryTransaction(transaction);

    return res.status(200).json({
      success: true,
      message: 'Webhook processed as failed payment',
      status: normalizedStatus,
    });
  }

  transaction.status = 'pending';
  await transaction.save();

  return res.status(200).json({
    success: true,
    message: 'Webhook received, transaction remains pending',
    status: normalizedStatus,
  });
});

const getPaymentStatus = asyncHandler(async (req, res) => {
  const data = await paymentService.getPaymentStatus({
    transactionId: req.params.transactionId,
    userId: req.user._id,
  });

  res.status(200).json({
    success: true,
    data,
  });
});

const verifyFawryTransactionStatus = asyncHandler(async (req, res) => {
  const data = await paymentService.verifyFawryTransactionStatus({
    transactionId: req.params.transactionId,
    userId: req.user._id,
  });

  res.status(200).json({
    success: true,
    data,
  });
});

const retryFawryCheckout = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).select(
    'fullName email phoneNumber'
  );

  if (!user) {
    throw new Error('User not found');
  }

  const data = await paymentService.retryFawryCheckout({
    transactionId: req.params.transactionId,
    user: {
      _id: user._id,
      fullName: user.fullName,
      email: user.email,
      phoneNumber: user.phoneNumber,
    },
  });

  res.status(200).json({
    success: true,
    data,
  });
});

const markTransactionRefunded = asyncHandler(async (req, res) => {
  const data = await paymentService.markTransactionRefunded({
    transactionId: req.params.transactionId,
    userId: req.user._id,
  });

  res.status(200).json({
    success: true,
    data,
  });
});

const refundMentorSessionPayment = asyncHandler(async (req, res) => {
  const data = await paymentService.refundMentorSessionPayment({
    sessionId: req.params.sessionId,
    initiatedByUserId: req.user._id,
    reason: req.body.reason || '',
  });

  res.status(200).json({
    success: true,
    data,
  });
});

const refundEventRegistrationPayment = asyncHandler(async (req, res) => {
  const data = await paymentService.refundEventRegistrationPayment({
    registrationId: req.params.registrationId,
    initiatedByUserId: req.user._id,
    reason: req.body.reason || '',
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
  handleFawryWebhook,
  getPaymentStatus,
  verifyFawryTransactionStatus,
  retryFawryCheckout,
  markTransactionRefunded,
  refundMentorSessionPayment,
  refundEventRegistrationPayment,
};