const Wallet = require('./wallet.model');
const PaymentMethod = require('./paymentMethod.model');
const Transaction = require('./transaction.model');
const notificationService = require('../notification/notification.service');
const {
  getFawryConfig,
  generateMerchantRef,
  buildHostedCheckoutPayload,
} = require('./providers/fawry.provider');
function round2(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

async function getOrCreateWallet(userId, currency = 'EGP') {
  let wallet = await Wallet.findOne({ userId });

  if (!wallet) {
    wallet = await Wallet.create({
      userId,
      availableBalance: 0,
      heldBalance: 0,
      currency,
    });
  }

  return wallet;
}

async function getDefaultPaymentMethod(userId) {
  return PaymentMethod.findOne({
    userId,
    isDefault: true,
    isActive: true,
  });
}

async function addPaymentMethod(userId, payload) {
  const method = await PaymentMethod.create({
    userId,
    provider: payload.provider || 'mock_card',
    brand: payload.brand || '',
    last4: payload.last4 || '',
    tokenOrReference: payload.tokenOrReference || '',
    holderName: payload.holderName || '',
    expiryMonth: payload.expiryMonth || null,
    expiryYear: payload.expiryYear || null,
    isDefault: !!payload.isDefault,
    isActive: true,
  });

  if (method.isDefault) {
    await PaymentMethod.updateMany(
      { userId, _id: { $ne: method._id } },
      { $set: { isDefault: false } }
    );
  }

  return method;
}

async function listPaymentMethods(userId) {
  return PaymentMethod.find({ userId, isActive: true }).sort({
    isDefault: -1,
    createdAt: -1,
  });
}

// Mock top-up for MVP/demo
async function depositToWallet(userId, amount, notes = 'Wallet top-up') {
  const wallet = await getOrCreateWallet(userId);
  const amt = round2(amount);

  if (amt <= 0) throw new Error('Amount must be greater than 0');

  wallet.availableBalance = round2(wallet.availableBalance + amt);
  await wallet.save();

  await Transaction.create({
    userId,
    type: 'deposit',
    amount: amt,
    currency: wallet.currency,
    status: 'completed',
    notes,
  });
    await notificationService.createNotification({
    userId,
    type: 'wallet_deposit',
    title: 'Wallet topped up',
    message: `${amt} ${wallet.currency} was added to your wallet.`,
    data: {
      amount: amt,
      currency: wallet.currency,
      availableBalance: wallet.availableBalance,
    },
  });

  return wallet;
}

async function holdFunds({ userId, sessionId, amount, paymentMethodId = null, currency = 'EGP' }) {
  const wallet = await getOrCreateWallet(userId, currency);
  const amt = round2(amount);

  if (amt <= 0) throw new Error('Invalid hold amount');

  if (wallet.availableBalance < amt) {
    throw new Error('Insufficient wallet balance');
  }

  wallet.availableBalance = round2(wallet.availableBalance - amt);
  wallet.heldBalance = round2(wallet.heldBalance + amt);
  await wallet.save();

  await Transaction.create({
    userId,
    sessionId,
    type: 'hold',
    amount: amt,
    currency,
    status: 'completed',
    paymentMethodId,
    notes: 'Session payment held',
  });

  return wallet;
}

async function releaseHeldFunds({ userId, sessionId, amount, currency = 'EGP' }) {
  const wallet = await getOrCreateWallet(userId, currency);
  const amt = round2(amount);

  if (amt <= 0) throw new Error('Invalid release amount');
  if (wallet.heldBalance < amt) throw new Error('Held balance is insufficient');

  wallet.heldBalance = round2(wallet.heldBalance - amt);
  wallet.availableBalance = round2(wallet.availableBalance + amt);
  await wallet.save();

  await Transaction.create({
    userId,
    sessionId,
    type: 'release',
    amount: amt,
    currency,
    status: 'completed',
    notes: 'Held amount released back to wallet',
  });

  return wallet;
}

async function captureHeldFunds({ userId, sessionId, amount, currency = 'EGP' }) {
  const wallet = await getOrCreateWallet(userId, currency);
  const amt = round2(amount);

  if (amt <= 0) throw new Error('Invalid capture amount');
  if (wallet.heldBalance < amt) throw new Error('Held balance is insufficient');

  wallet.heldBalance = round2(wallet.heldBalance - amt);
  await wallet.save();

  await Transaction.create({
    userId,
    sessionId,
    type: 'capture',
    amount: amt,
    currency,
    status: 'completed',
    notes: 'Held amount captured',
  });

  return wallet;
}

async function creditMentorWallet({ mentorUserId, sessionId, amount, currency = 'EGP' }) {
  const wallet = await getOrCreateWallet(mentorUserId, currency);
  const amt = round2(amount);

  if (amt <= 0) throw new Error('Invalid mentor credit amount');

  wallet.availableBalance = round2(wallet.availableBalance + amt);
  await wallet.save();

  await Transaction.create({
    userId: mentorUserId,
    sessionId,
    type: 'mentor_credit',
    amount: amt,
    currency,
    status: 'completed',
    notes: 'Mentor credited after completed session',
  });

    await notificationService.createNotification({
    userId: mentorUserId,
    type: 'wallet_credit',
    title: 'Wallet credited',
    message: `${amt} ${currency} was added to your wallet.`,
    data: {
      amount: amt,
      currency,
      availableBalance: wallet.availableBalance,
      sessionId,
    },
  });

  return wallet;
}

async function addPlatformFeeTransaction({ userId, sessionId, amount, currency = 'EGP' }) {
  const amt = round2(amount);

  await Transaction.create({
    userId,
    sessionId,
    type: 'platform_fee',
    amount: amt,
    currency,
    status: 'completed',
    notes: 'Platform fee deducted from session',
  });
}

async function getWalletSummary(userId) {
  const wallet = await getOrCreateWallet(userId);
  const transactions = await Transaction.find({ userId }).sort({ createdAt: -1 }).limit(20);

  return {
    wallet,
    recentTransactions: transactions,
  };
}
async function createFawryCheckout({
  user,
  amount,
  purpose,
  entityType,
  entityId = null,
  description,
  paymentMethod = '',
  sessionId = null,
  eventRegistrationId = null,
}) {
  const amt = round2(amount);

  if (amt <= 0) {
    throw new Error('Amount must be greater than 0');
  }

  if (!user || !user._id) {
    throw new Error('Valid user is required');
  }

  const { baseUrl } = getFawryConfig();

  const merchantRefNum = generateMerchantRef(
    entityType ? `${entityType}` : 'txn'
  );

  const transaction = await Transaction.create({
    userId: user._id,
    relatedUserId: null,
    sessionId,
    eventRegistrationId,
    type: purpose || 'deposit',
    amount: amt,
    currency: 'EGP',
    status: 'pending',
    paymentMethodId: null,
    provider: 'fawry',
    providerReference: merchantRefNum,
    providerStatus: 'INITIATED',
    entityType: entityType || 'other',
    entityId: entityId || null,
    checkoutUrl: '',
    paymentChannel: paymentMethod || '',
    reference: merchantRefNum,
    notes: description || 'Fawry checkout initiated',
    rawProviderResponse: null,
  });

  const payload = buildHostedCheckoutPayload({
    merchantRefNum,
    customerProfileId: String(user._id),
    customerName: user.fullName || 'SkillSync User',
    customerEmail: user.email || '',
    customerMobile: user.phoneNumber || '',
    amount: amt,
    description: description || 'SkillSync payment',
    returnUrl: process.env.FAWRY_RETURN_URL || '',
    paymentMethod,
  });

  const response = await fetch(`${baseUrl}/init`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const data = await response.json();

  if (!response.ok) {
    transaction.status = 'failed';
    transaction.providerStatus =
      data?.statusDescription ||
      data?.paymentStatus ||
      data?.statusCode ||
      'FAILED';
    transaction.rawProviderResponse = data;
    await transaction.save();

    throw new Error(
      data?.message || data?.statusDescription || 'Fawry checkout failed'
    );
  }

  transaction.providerStatus =
    data?.paymentStatus ||
    data?.statusDescription ||
    data?.statusCode ||
    'PENDING';

  if (data?.referenceNumber) {
    transaction.providerReference = String(data.referenceNumber);
  }

  transaction.checkoutUrl =
    data?.redirectUrl ||
    data?.paymentLink ||
    data?.url ||
    '';

  transaction.rawProviderResponse = data;

  await transaction.save();

  return {
    transactionId: transaction._id,
    merchantRefNum,
    provider: 'fawry',
    providerStatus: transaction.providerStatus,
    redirectUrl: transaction.checkoutUrl || null,
    raw: data,
  };
}
async function applySuccessfulFawryTopup(transaction) {
  if (!transaction) {
    throw new Error('Transaction is required');
  }

  // only handle Fawry wallet top-ups here
  if (transaction.provider !== 'fawry') {
    return transaction;
  }

  if (transaction.type !== 'deposit') {
    return transaction;
  }

  // prevent double processing
  if (transaction.providerStatus === 'TOPUP_APPLIED') {
    return transaction;
  }

  const wallet = await getOrCreateWallet(transaction.userId, transaction.currency || 'EGP');
  const amt = round2(transaction.amount);

  if (amt <= 0) {
    throw new Error('Invalid top-up amount');
  }

  wallet.availableBalance = round2(wallet.availableBalance + amt);
  await wallet.save();

  await Transaction.create({
    userId: transaction.userId,
    relatedUserId: null,
    sessionId: null,
    type: 'deposit',
    amount: amt,
    currency: transaction.currency || 'EGP',
    status: 'completed',
    provider: 'internal',
    providerReference: '',
    providerStatus: 'TOPUP_CREDIT',
    reference: transaction._id.toString(),
    notes: 'Wallet credited from successful Fawry payment',
  });

  transaction.status = 'completed';
  transaction.providerStatus = 'TOPUP_APPLIED';
  await transaction.save();

  await notificationService.createNotification({
    userId: transaction.userId,
    type: 'wallet_deposit',
    title: 'Wallet topped up',
    message: `${amt} ${transaction.currency || 'EGP'} was added to your wallet from Fawry payment.`,
    data: {
      amount: amt,
      currency: transaction.currency || 'EGP',
      transactionId: transaction._id,
    },
  });

  return transaction;
}
module.exports = {
  getOrCreateWallet,
  getDefaultPaymentMethod,
  addPaymentMethod,
  listPaymentMethods,
  depositToWallet,
  holdFunds,
  releaseHeldFunds,
  captureHeldFunds,
  creditMentorWallet,
  addPlatformFeeTransaction,
  getWalletSummary,
  createFawryCheckout,
  applySuccessfulFawryTopup,
};