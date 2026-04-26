const PayoutMethod = require('./payoutMethod.model');
const WithdrawalRequest = require('./withdrawalRequest.model');
const Wallet = require('./wallet.model');
const Transaction = require('./transaction.model');
const notificationService = require('../notification/notification.service');
const auditService = require('../audit/audit.service');

function round2(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

const MIN_WITHDRAWAL_AMOUNT = 50;

function maskValue(value = '', visibleLast = 4) {
  const str = String(value || '').trim();
  if (!str) return '';
  if (str.length <= visibleLast) return str;
  return '*'.repeat(str.length - visibleLast) + str.slice(-visibleLast);
}

function mapPayoutMethodSafe(method) {
  if (!method) return null;

  return {
    _id: method._id,
    mentorUserId: method.mentorUserId,
    methodType: method.methodType,
    accountHolderName: method.accountHolderName,
    bankName: method.bankName,
    bankAccountNumberMasked: maskValue(method.bankAccountNumber),
    ibanMasked: maskValue(method.iban),
    walletProvider: method.walletProvider,
    walletNumberMasked: maskValue(method.walletNumber),
    isDefault: method.isDefault,
    isActive: method.isActive,
    createdAt: method.createdAt,
    updatedAt: method.updatedAt,
  };
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

async function addPayoutMethod(mentorUserId, payload = {}) {
  const methodType = String(payload.methodType || '').trim();

  if (!['bank_transfer', 'mobile_wallet'].includes(methodType)) {
    throw new Error('methodType must be bank_transfer or mobile_wallet');
  }

  const data = {
    mentorUserId,
    methodType,
    accountHolderName: String(payload.accountHolderName || '').trim(),
    bankName: String(payload.bankName || '').trim(),
    bankAccountNumber: String(payload.bankAccountNumber || '').trim(),
    iban: String(payload.iban || '').trim(),
    walletProvider: String(payload.walletProvider || '').trim(),
    walletNumber: String(payload.walletNumber || '').trim(),
    isDefault: Boolean(payload.isDefault),
    isActive: true,
  };

  if (methodType === 'bank_transfer') {
    if (!data.accountHolderName || !data.bankName || !data.bankAccountNumber) {
      throw new Error(
        'accountHolderName, bankName, and bankAccountNumber are required for bank_transfer'
      );
    }
  }

  if (methodType === 'mobile_wallet') {
    if (!data.accountHolderName || !data.walletProvider || !data.walletNumber) {
      throw new Error(
        'accountHolderName, walletProvider, and walletNumber are required for mobile_wallet'
      );
    }
  }

  const method = await PayoutMethod.create(data);

  if (method.isDefault) {
    await PayoutMethod.updateMany(
      { mentorUserId, _id: { $ne: method._id } },
      { $set: { isDefault: false } }
    );
  }

  return mapPayoutMethodSafe(method);
}

async function listPayoutMethods(mentorUserId) {
  const methods = await PayoutMethod.find({
  mentorUserId,
  isActive: true,
}).sort({ isDefault: -1, createdAt: -1 });

return methods.map(mapPayoutMethodSafe);
}

async function requestWithdrawal(mentorUserId, payload = {}) {
  const amount = round2(payload.amount);
  const payoutMethodId = String(payload.payoutMethodId || '').trim();

  if (!Number.isFinite(amount) || amount <= 0) {
  throw new Error('amount must be greater than 0');
}

if (amount < MIN_WITHDRAWAL_AMOUNT) {
  throw new Error(`Minimum withdrawal amount is ${MIN_WITHDRAWAL_AMOUNT} EGP`);
}

  if (!payoutMethodId) {
    throw new Error('payoutMethodId is required');
  }

  const payoutMethod = await PayoutMethod.findOne({
    _id: payoutMethodId,
    mentorUserId,
    isActive: true,
  });

  if (!payoutMethod) {
    throw new Error('Payout method not found');
  }

  const wallet = await getOrCreateWallet(mentorUserId);

  if (Number(wallet.availableBalance || 0) < amount) {
    throw new Error('Insufficient available balance');
  }

  wallet.availableBalance = round2(Number(wallet.availableBalance || 0) - amount);
  wallet.heldBalance = round2(Number(wallet.heldBalance || 0) + amount);
  await wallet.save();

  const request = await WithdrawalRequest.create({
    mentorUserId,
    payoutMethodId: payoutMethod._id,
    amount,
    currency: wallet.currency || 'EGP',
    status: 'pending',
  });

  await Transaction.create({
    userId: mentorUserId,
    amount,
    currency: wallet.currency || 'EGP',
    type: 'withdraw',
    provider: 'internal',
    providerStatus: 'WITHDRAWAL_REQUESTED',
    status: 'pending',
    entityType: 'other',
    entityId: request._id,
    notes: 'Mentor withdrawal requested',
  });

  return {
    request,
    wallet,
  };
}

async function listMyWithdrawalRequests(mentorUserId) {
  const requests = await WithdrawalRequest.find({ mentorUserId })
  .populate('payoutMethodId')
  .sort({ createdAt: -1 });

return requests.map((item) => ({
  ...item.toObject(),
  payoutMethodId: mapPayoutMethodSafe(item.payoutMethodId),
}));
}

async function listAllWithdrawalRequests(filters = {}) {
  const query = {};

  if (filters.status) {
    query.status = filters.status;
  }

  const requests = await WithdrawalRequest.find(query)
  .populate('mentorUserId', 'fullName email phoneNumber')
  .populate('payoutMethodId')
  .populate('reviewedByUserId', 'fullName email')
  .sort({ createdAt: -1 });

return requests.map((item) => ({
  ...item.toObject(),
  payoutMethodId: mapPayoutMethodSafe(item.payoutMethodId),
}));
}

async function approveWithdrawalRequest(withdrawalRequestId, adminUserId, adminNote = '') {
  const request = await WithdrawalRequest.findById(withdrawalRequestId);

  if (!request) {
    throw new Error('Withdrawal request not found');
  }

  if (request.status !== 'pending') {
    throw new Error('Only pending withdrawal requests can be approved');
  }

  request.status = 'approved';
  request.adminNote = String(adminNote || '').trim();
  request.reviewedByUserId = adminUserId;
  request.reviewedAt = new Date();
  await request.save();

  await Transaction.findOneAndUpdate(
    {
      userId: request.mentorUserId,
      type: 'withdraw',
      entityId: request._id,
      status: 'pending',
    },
    {
      $set: {
        providerStatus: 'WITHDRAWAL_APPROVED',
      },
    },
    { sort: { createdAt: -1 } }
  );


  await notificationService.createNotification({
  userId: request.mentorUserId,
  type: 'withdrawal_approved',
  title: 'Withdrawal approved',
  message: `Your withdrawal request for ${request.amount} ${request.currency} was approved.`,
  data: {
    withdrawalRequestId: request._id,
    amount: request.amount,
    currency: request.currency,
    status: request.status,
  },
});

await auditService.createAuditLog({
  action: 'withdrawal_approved',
  entityType: 'withdrawal_request',
  entityId: request._id,
  message: `Withdrawal request approved: ${request.amount} ${request.currency}`,
  performedByUserId: adminUserId,
  metadata: {
    mentorUserId: request.mentorUserId,
    adminNote: request.adminNote,
  },
});

  return request;
}

async function rejectWithdrawalRequest(withdrawalRequestId, adminUserId, adminNote = '') {
  const request = await WithdrawalRequest.findById(withdrawalRequestId);

  if (!request) {
    throw new Error('Withdrawal request not found');
  }

  if (!['pending', 'approved'].includes(request.status)) {
    throw new Error('Only pending or approved withdrawal requests can be rejected');
  }

  const wallet = await getOrCreateWallet(request.mentorUserId, request.currency || 'EGP');

  wallet.heldBalance = round2(Number(wallet.heldBalance || 0) - Number(request.amount || 0));
  wallet.availableBalance = round2(
    Number(wallet.availableBalance || 0) + Number(request.amount || 0)
  );
  await wallet.save();

  request.status = 'rejected';
  request.adminNote = String(adminNote || '').trim();
  request.reviewedByUserId = adminUserId;
  request.reviewedAt = new Date();
  await request.save();

  await Transaction.findOneAndUpdate(
    {
      userId: request.mentorUserId,
      type: 'withdraw',
      entityId: request._id,
    },
    {
      $set: {
        status: 'failed',
        providerStatus: 'WITHDRAWAL_REJECTED',
      },
    },
    { sort: { createdAt: -1 } }
  );

  await notificationService.createNotification({
  userId: request.mentorUserId,
  type: 'withdrawal_rejected',
  title: 'Withdrawal rejected',
  message: `Your withdrawal request for ${request.amount} ${request.currency} was rejected.`,
  data: {
    withdrawalRequestId: request._id,
    amount: request.amount,
    currency: request.currency,
    status: request.status,
    adminNote: request.adminNote,
  },
});

await auditService.createAuditLog({
  action: 'withdrawal_rejected',
  entityType: 'withdrawal_request',
  entityId: request._id,
  message: `Withdrawal request rejected: ${request.amount} ${request.currency}`,
  performedByUserId: adminUserId,
  metadata: {
    mentorUserId: request.mentorUserId,
    adminNote: request.adminNote,
  },
});

  return {
    request,
    wallet,
  };
}

async function markWithdrawalRequestPaid(
  withdrawalRequestId,
  adminUserId,
  payoutReference = '',
  adminNote = ''
) {
  const request = await WithdrawalRequest.findById(withdrawalRequestId);

  if (!request) {
    throw new Error('Withdrawal request not found');
  }

  if (!['pending', 'approved'].includes(request.status)) {
    throw new Error('Only pending or approved withdrawal requests can be marked as paid');
  }

  const wallet = await getOrCreateWallet(request.mentorUserId, request.currency || 'EGP');

  if (Number(wallet.heldBalance || 0) < Number(request.amount || 0)) {
    throw new Error('Held balance is insufficient for payout completion');
  }

  wallet.heldBalance = round2(Number(wallet.heldBalance || 0) - Number(request.amount || 0));
  await wallet.save();

  request.status = 'paid';
  request.payoutReference = String(payoutReference || '').trim();
  request.adminNote = String(adminNote || '').trim();
  request.reviewedByUserId = adminUserId;
  request.reviewedAt = request.reviewedAt || new Date();
  request.paidAt = new Date();
  await request.save();

  await Transaction.findOneAndUpdate(
    {
      userId: request.mentorUserId,
      type: 'withdraw',
      entityId: request._id,
    },
    {
      $set: {
        status: 'completed',
        providerStatus: 'WITHDRAWAL_PAID',
        reference: String(payoutReference || '').trim(),
        notes: 'Mentor withdrawal paid',
      },
    },
    { sort: { createdAt: -1 } }
  );

  await notificationService.createNotification({
  userId: request.mentorUserId,
  type: 'withdrawal_paid',
  title: 'Withdrawal paid',
  message: `Your withdrawal request for ${request.amount} ${request.currency} was marked as paid.`,
  data: {
    withdrawalRequestId: request._id,
    amount: request.amount,
    currency: request.currency,
    status: request.status,
    payoutReference: request.payoutReference,
  },
});

await auditService.createAuditLog({
  action: 'withdrawal_paid',
  entityType: 'withdrawal_request',
  entityId: request._id,
  message: `Withdrawal request paid: ${request.amount} ${request.currency}`,
  performedByUserId: adminUserId,
  metadata: {
    mentorUserId: request.mentorUserId,
    payoutReference: request.payoutReference,
    adminNote: request.adminNote,
  },
});

  return {
    request,
    wallet,
  };
}

async function cancelMyWithdrawalRequest(mentorUserId, withdrawalRequestId) {
  const request = await WithdrawalRequest.findOne({
    _id: withdrawalRequestId,
    mentorUserId,
  });

  if (!request) {
    throw new Error('Withdrawal request not found');
  }

  if (request.status !== 'pending') {
    throw new Error('Only pending withdrawal requests can be cancelled');
  }

  const wallet = await getOrCreateWallet(request.mentorUserId, request.currency || 'EGP');

  wallet.heldBalance = round2(Number(wallet.heldBalance || 0) - Number(request.amount || 0));
  wallet.availableBalance = round2(
    Number(wallet.availableBalance || 0) + Number(request.amount || 0)
  );
  await wallet.save();

  request.status = 'cancelled';
  await request.save();

  await Transaction.findOneAndUpdate(
    {
      userId: request.mentorUserId,
      type: 'withdraw',
      entityId: request._id,
    },
    {
      $set: {
        status: 'failed',
        providerStatus: 'WITHDRAWAL_CANCELLED',
      },
    },
    { sort: { createdAt: -1 } }
  );

  await notificationService.createNotification({
    userId: request.mentorUserId,
    type: 'withdrawal_cancelled',
    title: 'Withdrawal cancelled',
    message: `Your withdrawal request for ${request.amount} ${request.currency} was cancelled.`,
    data: {
      withdrawalRequestId: request._id,
      amount: request.amount,
      currency: request.currency,
      status: request.status,
    },
  });

  return {
    request,
    wallet,
  };
}

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