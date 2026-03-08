const Wallet = require('./wallet.model');
const PaymentMethod = require('./paymentMethod.model');
const Transaction = require('./transaction.model');

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
};