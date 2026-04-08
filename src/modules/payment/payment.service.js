const Wallet = require('./wallet.model');
const PaymentMethod = require('./paymentMethod.model');
const Transaction = require('./transaction.model');
const notificationService = require('../notification/notification.service');
const MentorSession = require('../mentor/mentorSession.model');
const EventRegistration = require('../events/eventRegistration.model');
const GroupEvent = require('../events/groupEvent.model');
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
async function captureHeldFunds({
  userId,
  sessionId = null,
  eventRegistrationId = null,
  amount,
  currency = 'EGP',
}) {
  const wallet = await getOrCreateWallet(userId, currency);
  const amt = round2(amount);

  if (amt <= 0) throw new Error('Invalid capture amount');
  if (wallet.heldBalance < amt) throw new Error('Held balance is insufficient');

  wallet.heldBalance = round2(wallet.heldBalance - amt);
  await wallet.save();

  await Transaction.create({
    userId,
    sessionId,
    eventRegistrationId,
    type: 'capture',
    amount: amt,
    currency,
    status: 'completed',
    notes: 'Held amount captured',
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

async function releaseHeldFunds({
  userId,
  sessionId = null,
  eventRegistrationId = null,
  amount,
  currency = 'EGP',
  reason = 'release',
}) {
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
    eventRegistrationId,
    type: 'release',
    amount: amt,
    currency,
    status: 'completed',
    notes: reason || 'Held amount released back to wallet',
  });

  return wallet;
}

async function creditMentorWallet({
  mentorUserId,
  sessionId,
  amount,
  currency = 'EGP',
  reason = 'Mentor credited after completed session',
}) {
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
    notes: reason,
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

async function addPlatformFeeTransaction({
  userId,
  sessionId,
  amount,
  currency = 'EGP',
  notes = 'Platform fee deducted from session',
}) {
  const amt = round2(amount);

  await Transaction.create({
    userId,
    sessionId,
    type: 'platform_fee',
    amount: amt,
    currency,
    status: 'completed',
    notes,
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
async function applySuccessfulFawryTransaction(transaction) {
  if (!transaction) {
    throw new Error('Transaction is required');
  }

  if (transaction.provider !== 'fawry') {
    return transaction;
  }

  // prevent double processing
  if (transaction.providerStatus === 'APPLIED_SUCCESS') {
    return transaction;
  }

  const entityType = transaction.entityType;
  const currency = transaction.currency || 'EGP';
  const amt = round2(transaction.amount);

  if (amt <= 0) {
    throw new Error('Invalid transaction amount');
  }

  // 1) Wallet top-up
  if (entityType === 'wallet_topup') {
    const wallet = await getOrCreateWallet(transaction.userId, currency);

    wallet.availableBalance = round2(wallet.availableBalance + amt);
    await wallet.save();

    await Transaction.create({
      userId: transaction.userId,
      relatedUserId: null,
      sessionId: null,
      eventRegistrationId: null,
      type: 'deposit',
      amount: amt,
      currency,
      status: 'completed',
      paymentMethodId: null,
      provider: 'internal',
      providerReference: '',
      providerStatus: 'TOPUP_CREDIT',
      entityType: 'wallet_topup',
      entityId: transaction.entityId || null,
      checkoutUrl: '',
      paymentChannel: '',
      reference: transaction._id.toString(),
      notes: 'Wallet credited from successful Fawry payment',
      rawProviderResponse: null,
    });

    transaction.status = 'completed';
    transaction.providerStatus = 'APPLIED_SUCCESS';
    await transaction.save();

    await notificationService.createNotification({
      userId: transaction.userId,
      type: 'wallet_deposit',
      title: 'Wallet topped up',
      message: `${amt} ${currency} was added to your wallet from Fawry payment.`,
      data: {
        amount: amt,
        currency,
        transactionId: transaction._id,
      },
    });

    return transaction;
  }

  // 2) Mentor session payment
  if (entityType === 'mentor_session') {
    const session = await MentorSession.findById(transaction.entityId);

    if (!session) {
      throw new Error('Related mentor session not found');
    }

    // We treat successful Fawry payment as the external equivalent of "held"
    session.paymentStatus = 'held';
    await session.save();

    transaction.status = 'completed';
    transaction.providerStatus = 'APPLIED_SUCCESS';
    transaction.sessionId = session._id;
    await transaction.save();

    await notificationService.createNotification({
      userId: session.userId,
      type: 'payment_held',
      title: 'Session payment confirmed',
      message: `Your payment of ${amt} ${currency} for the mentor session was confirmed.`,
      data: {
        sessionId: session._id,
        amount: amt,
        currency,
        paymentStatus: session.paymentStatus,
        transactionId: transaction._id,
      },
    });

    await notificationService.createNotification({
      userId: session.mentorUserId,
      type: 'mentor_session_requested',
      title: 'Paid session request received',
      message: 'A new mentor session request has been paid and is ready for your review.',
      data: {
        sessionId: session._id,
        amount: amt,
        currency,
      },
    });

        await notificationService.createNotification({
      userId: session.userId,
      type: 'payment_success',
      title: 'Session payment successful',
      message: `Your mentor session payment was successful.`,
      data: {
        sessionId: session._id,
        transactionId: transaction._id,
        amount: amt,
        currency,
      },
    });

    return transaction;
  }

  // 3) Group event registration payment
    if (entityType === 'group_event') {
    const registration = await EventRegistration.findById(transaction.entityId).populate('eventId');

    if (!registration) {
      throw new Error('Related event registration not found');
    }

    if (!registration.eventId) {
      throw new Error('Related event not found');
    }

    registration.paymentStatus = 'held';
    await registration.save();

    const event = registration.eventId;

    // increment only once on successful payment application
    event.registeredCount = Number(event.registeredCount || 0) + 1;

    if (event.registeredCount > Number(event.capacity || 0)) {
      event.registeredCount = Number(event.capacity || 0);
    }

    await event.save();

    transaction.status = 'completed';
    transaction.providerStatus = 'APPLIED_SUCCESS';
    transaction.eventRegistrationId = registration._id;
    await transaction.save();

    await notificationService.createNotification({
      userId: registration.userId,
      type: 'event_registered',
      title: 'Event payment confirmed',
      message: `Your payment for "${event.title || 'event'}" was confirmed.`,
      data: {
        registrationId: registration._id,
        eventId: event._id || null,
        amount: amt,
        currency,
        paymentStatus: registration.paymentStatus,
        transactionId: transaction._id,
      },
    });
        await notificationService.createNotification({
      userId: registration.userId,
      type: 'payment_success',
      title: 'Event payment successful',
      message: `Your event registration payment was successful.`,
      data: {
        registrationId: registration._id,
        transactionId: transaction._id,
        amount: amt,
        currency,
      },
    });

    return transaction;
  }

  // fallback: mark complete but do not apply business action
  transaction.status = 'completed';
  transaction.providerStatus = 'APPLIED_SUCCESS';
  await transaction.save();

  return transaction;
}

async function applyFailedFawryTransaction(transaction) {
  if (!transaction) {
    throw new Error('Transaction is required');
  }

  if (transaction.provider !== 'fawry') {
    return transaction;
  }

  const entityType = transaction.entityType;

  // Wallet top-up failure: nothing to credit
  if (entityType === 'wallet_topup') {
    transaction.status = 'failed';
    transaction.providerStatus = transaction.providerStatus || 'FAILED';
    await transaction.save();

    await notificationService.createNotification({
      userId: transaction.userId,
      type: 'payment_failed',
      title: 'Top-up failed',
      message: `Your wallet top-up payment failed.`,
      data: {
        transactionId: transaction._id,
        entityType,
        amount: transaction.amount,
        currency: transaction.currency,
      },
    });

    return transaction;
  }

  // Mentor session failure
  if (entityType === 'mentor_session') {
    const session = await MentorSession.findById(transaction.entityId);

    if (session) {
      session.paymentStatus = 'failed';
      await session.save();

      await notificationService.createNotification({
        userId: session.userId,
        type: 'payment_failed',
        title: 'Session payment failed',
        message: 'Your mentor session payment failed.',
        data: {
          sessionId: session._id,
          transactionId: transaction._id,
          amount: transaction.amount,
          currency: transaction.currency,
        },
      });

      await notificationService.createNotification({
        userId: session.mentorUserId,
        type: 'mentor_session_payment_failed',
        title: 'Session payment failed',
        message: 'A mentor session request payment failed.',
        data: {
          sessionId: session._id,
          transactionId: transaction._id,
        },
      });

      await notificationService.createNotification({
        userId: session.userId,
        type: 'payment_retry_available',
        title: 'You can retry payment',
        message: 'Your mentor session payment failed. You can try again.',
        data: {
          sessionId: session._id,
          transactionId: transaction._id,
        },
      });
    }

    transaction.status = 'failed';
    transaction.providerStatus = transaction.providerStatus || 'FAILED';
    await transaction.save();
    return transaction;
  }

       

  // Group event payment failure
   if (entityType === 'group_event') {
    const registration = await EventRegistration.findById(transaction.entityId).populate('eventId');

    if (registration) {
      registration.paymentStatus = 'released';
      await registration.save();

      const event = registration.eventId;
      if (event && Number(event.registeredCount || 0) > 0) {
        event.registeredCount = Math.max(0, Number(event.registeredCount || 0) - 1);
        await event.save();
      }

      await notificationService.createNotification({
        userId: registration.userId,
        type: 'payment_failed',
        title: 'Event payment failed',
        message: `Your payment for "${event?.title || 'event'}" failed.`,
        data: {
          registrationId: registration._id,
          eventId: event?._id || null,
          transactionId: transaction._id,
          amount: transaction.amount,
          currency: transaction.currency,
        },
      });

      await notificationService.createNotification({
        userId: registration.userId,
        type: 'payment_retry_available',
        title: 'You can retry payment',
        message: 'Your event payment failed. You can try again.',
        data: {
          registrationId: registration._id,
          transactionId: transaction._id,
        },
      });
    }

    transaction.status = 'failed';
    transaction.providerStatus = transaction.providerStatus || 'FAILED';
    await transaction.save();
    return transaction;
  }

  transaction.status = 'failed';
  await transaction.save();
  return transaction;
}
async function getPaymentStatus({ transactionId, userId }) {
  if (!transactionId) {
    throw new Error('transactionId is required');
  }

  const transaction = await Transaction.findById(transactionId)
    .populate('sessionId')
    .populate('eventRegistrationId');

  if (!transaction) {
    throw new Error('Transaction not found');
  }

  // owner only
  if (String(transaction.userId) !== String(userId)) {
    throw new Error('You are not allowed to access this transaction');
  }

  let session = null;
  let eventRegistration = null;

   if (transaction.sessionId) {
  const sessionPaymentStatus = transaction.sessionId.paymentStatus;
  const sessionStatus = transaction.sessionId.status;

  session = {
    id: transaction.sessionId._id,
    status: sessionStatus,
    paymentStatus: sessionPaymentStatus,
    method: transaction.sessionId.method,
    durationMinutes: transaction.sessionId.durationMinutes,
    totalAmount: transaction.sessionId.totalAmount,
    currency: transaction.sessionId.currency,
    scheduledDate: transaction.sessionId.scheduledDate,
    scheduledStartTime: transaction.sessionId.scheduledStartTime,
    scheduledEndTime: transaction.sessionId.scheduledEndTime,
    isPaymentConfirmed: ['held', 'captured'].includes(sessionPaymentStatus),
    isReadyForMentorProcessing:
      ['held', 'captured'].includes(sessionPaymentStatus) &&
      ['scheduled', 'started', 'active', 'completed'].includes(sessionStatus),
    isRefunded: sessionPaymentStatus === 'refunded',
    isClosed: ['completed', 'cancelled', 'expired', 'user_no_show'].includes(
      sessionStatus
    ),
  };
}

    if (transaction.eventRegistrationId) {
    const registrationPaymentStatus = transaction.eventRegistrationId.paymentStatus;

    eventRegistration = {
      id: transaction.eventRegistrationId._id,
      paymentStatus: registrationPaymentStatus,
      attended: transaction.eventRegistrationId.attended,
      amountPaid: transaction.eventRegistrationId.amountPaid,
      currency: transaction.eventRegistrationId.currency,

      // frontend-friendly flag
      isConfirmed: ['held', 'captured'].includes(registrationPaymentStatus),
    };
  }

  return {
    transaction: {
      id: transaction._id,
      type: transaction.type,
      amount: transaction.amount,
      currency: transaction.currency,
      status: transaction.status,
      provider: transaction.provider,
      providerReference: transaction.providerReference,
      providerStatus: transaction.providerStatus,
      entityType: transaction.entityType,
      entityId: transaction.entityId,
      checkoutUrl: transaction.checkoutUrl,
      paymentChannel: transaction.paymentChannel,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,

      // frontend-friendly flag
      isSuccessful: transaction.status === 'completed',
    },
    session,
    eventRegistration,
  };
}

async function verifyFawryTransactionStatus({ transactionId, userId }) {
  if (!transactionId) {
    throw new Error('transactionId is required');
  }

  const transaction = await Transaction.findById(transactionId);

  if (!transaction) {
    throw new Error('Transaction not found');
  }

  if (String(transaction.userId) !== String(userId)) {
    throw new Error('You are not allowed to access this transaction');
  }

  return {
    id: transaction._id,
    status: transaction.status,
    provider: transaction.provider,
    providerReference: transaction.providerReference,
    providerStatus: transaction.providerStatus,
    entityType: transaction.entityType,
    entityId: transaction.entityId,
    checkoutUrl: transaction.checkoutUrl,
    isSuccessful: transaction.status === 'completed',
  };
}
async function retryFawryCheckout({ transactionId, user }) {
  if (!transactionId) {
    throw new Error('transactionId is required');
  }

  const oldTransaction = await Transaction.findById(transactionId);

  if (!oldTransaction) {
    throw new Error('Transaction not found');
  }

  if (String(oldTransaction.userId) !== String(user._id)) {
    throw new Error('You are not allowed to retry this transaction');
  }

  if (oldTransaction.provider !== 'fawry') {
    throw new Error('Only Fawry transactions can be retried');
  }

  if (oldTransaction.status === 'completed') {
    throw new Error('Completed transactions cannot be retried');
  }

  return createFawryCheckout({
    user,
    amount: oldTransaction.amount,
    purpose: oldTransaction.type,
    entityType: oldTransaction.entityType,
    entityId: oldTransaction.entityId || null,
    description: oldTransaction.notes || 'Retry Fawry checkout',
    paymentMethod: oldTransaction.paymentChannel || '',
    sessionId: oldTransaction.sessionId || null,
    eventRegistrationId: oldTransaction.eventRegistrationId || null,
  });
}
async function markTransactionRefunded({ transactionId, userId }) {
  if (!transactionId) {
    throw new Error('transactionId is required');
  }

  const transaction = await Transaction.findById(transactionId);
  if (!transaction) {
    throw new Error('Transaction not found');
  }

  if (String(transaction.userId) !== String(userId)) {
    throw new Error('You are not allowed to update this transaction');
  }

  transaction.providerStatus = 'REFUNDED';
  transaction.status = 'completed';
  transaction.notes = 'Marked refunded manually';
  await transaction.save();

  await notificationService.createNotification({
    userId,
    type: 'payment_refunded',
    title: 'Payment refunded',
    message: `${transaction.amount} ${transaction.currency} was marked as refunded.`,
    data: {
      transactionId: transaction._id,
      amount: transaction.amount,
      currency: transaction.currency,
      entityType: transaction.entityType,
      entityId: transaction.entityId,
      isManual: true,
    },
  });

  return transaction;
}
async function debitMentorWalletForRefund({
  mentorUserId,
  sessionId = null,
  amount,
  currency = 'EGP',
  reason = 'mentor_session_refund',
}) {
  if (!mentorUserId) {
    throw new Error('mentorUserId is required');
  }

  const wallet = await getOrCreateWallet(mentorUserId, currency);

  if (Number(wallet.availableBalance || 0) < Number(amount || 0)) {
    throw new Error(
      'Mentor wallet balance is insufficient to reverse payout. Manual admin settlement is required.'
    );
  }

  wallet.availableBalance = Number(wallet.availableBalance || 0) - Number(amount || 0);
  await wallet.save();

  const debitTx = await Transaction.create({
    userId: mentorUserId,
    sessionId,
    amount: Number(amount || 0),
    currency,
    type: 'refund',
    provider: 'internal',
    providerStatus: 'REFUND_DEBIT',
    status: 'completed',
    entityType: 'mentor_session_refund',
    entityId: sessionId || null,
    notes: reason,
  });

  return debitTx;
}

async function refundMentorSessionPayment({
  sessionId,
  initiatedByUserId,
  reason = '',
}) {
  if (!sessionId) {
    throw new Error('sessionId is required');
  }

  const session = await MentorSession.findById(sessionId);

  if (!session) {
    throw new Error('Session not found');
  }

  const transaction = await Transaction.findOne({
    entityType: 'mentor_session',
    entityId: session._id,
    status: { $in: ['pending', 'completed', 'failed'] },
  }).sort({ createdAt: -1 });

  if (!transaction) {
    throw new Error('No transaction found for this session');
  }

  if (String(transaction.userId) !== String(initiatedByUserId)) {
    throw new Error('You are not allowed to refund this session');
  }

  if (session.status === 'user_no_show') {
    throw new Error('No refund is allowed for user no-show sessions');
  }

  if (session.paymentStatus === 'refunded') {
    throw new Error('This session has already been refunded');
  }

  // Case 1: held only, not captured yet
  if (session.paymentStatus === 'held') {
    await releaseHeldFunds({
      userId: session.userId,
      sessionId: session._id,
      amount: session.totalAmount,
      currency: session.currency,
      reason: reason || 'mentor_session_refund_before_capture',
    });

    session.paymentStatus = 'refunded';
    await session.save();

    transaction.providerStatus = 'REFUNDED';
    transaction.status = 'completed';
    transaction.notes = reason || transaction.notes || 'Refunded from held payment';
    await transaction.save();

    await notificationService.createNotification({
      userId: session.userId,
      type: 'payment_refunded',
      title: 'Session payment refunded',
      message: `${session.totalAmount} ${session.currency} was refunded for your session.`,
      data: {
        sessionId: session._id,
        transactionId: transaction._id,
        amount: session.totalAmount,
        currency: session.currency,
      },
    });

    return {
      session,
      transaction,
      refundMode: 'release_hold',
    };
  }

  // Case 2: captured and maybe paid out already
  if (session.paymentStatus === 'captured') {
    if (session.payoutTransferred) {
      await debitMentorWalletForRefund({
        mentorUserId: session.mentorUserId,
        sessionId: session._id,
        amount: session.mentorNetAmount,
        currency: session.currency,
        reason:
          reason || `Reversal of mentor payout for refunded session ${session._id}`,
      });

      session.payoutTransferred = false;
    }

    session.paymentStatus = 'refunded';
    await session.save();

    transaction.providerStatus = 'REFUNDED';
    transaction.status = 'completed';
    transaction.notes = reason || transaction.notes || 'Refunded after capture';
    await transaction.save();

    await notificationService.createNotification({
      userId: session.userId,
      type: 'payment_refunded',
      title: 'Session payment refunded',
      message: `${session.totalAmount} ${session.currency} was refunded for your session.`,
      data: {
        sessionId: session._id,
        transactionId: transaction._id,
        amount: session.totalAmount,
        currency: session.currency,
      },
    });

     await notificationService.createNotification({
      userId: session.mentorUserId,
      type: 'mentor_payout_reversed',
      title: 'Mentor payout reversed',
      message: `A payout for session ${session._id} was reversed due to a refund.`,
      data: {
        sessionId: session._id,
        mentorNetAmount: session.mentorNetAmount,
        currency: session.currency,
      },
    });
    return {
      session,
      transaction,
      refundMode: 'captured_refund',
    };
  }

  throw new Error('This session is not in a refundable payment state');
}

async function refundEventRegistrationPayment({
  registrationId,
  initiatedByUserId,
  reason = '',
}) {
  if (!registrationId) {
    throw new Error('registrationId is required');
  }

  const registration = await EventRegistration.findById(registrationId).populate('eventId');

  if (!registration) {
    throw new Error('Event registration not found');
  }

  const transaction = await Transaction.findOne({
    entityType: 'group_event',
    entityId: registration._id,
    status: { $in: ['pending', 'completed', 'failed'] },
  }).sort({ createdAt: -1 });

  if (!transaction) {
    throw new Error('No transaction found for this event registration');
  }

  if (String(transaction.userId) !== String(initiatedByUserId)) {
    throw new Error('You are not allowed to refund this event payment');
  }

  if (registration.paymentStatus === 'refunded') {
    throw new Error('This event registration has already been refunded');
  }

  if (registration.paymentStatus === 'held') {
    await releaseHeldFunds({
      userId: registration.userId,
      amount: registration.amountPaid,
      currency: registration.currency,
      reason: reason || 'group_event_refund_before_capture',
      eventRegistrationId: registration._id,
    });

    registration.paymentStatus = 'refunded';
    await registration.save();

    if (registration.eventId && Number(registration.eventId.registeredCount || 0) > 0) {
      registration.eventId.registeredCount = Math.max(
        0,
        Number(registration.eventId.registeredCount || 0) - 1
      );
      await registration.eventId.save();
    }

    transaction.providerStatus = 'REFUNDED';
    transaction.status = 'completed';
    transaction.notes = reason || transaction.notes || 'Event refund from held payment';
    await transaction.save();

    await notificationService.createNotification({
      userId: registration.userId,
      type: 'payment_refunded',
      title: 'Event payment refunded',
      message: `${registration.amountPaid} ${registration.currency} was refunded for your event registration.`,
      data: {
        registrationId: registration._id,
        transactionId: transaction._id,
        amount: registration.amountPaid,
        currency: registration.currency,
      },
    });

    return {
      registration,
      transaction,
      refundMode: 'release_hold',
    };
  }

  if (registration.paymentStatus === 'captured') {
    registration.paymentStatus = 'refunded';
    await registration.save();

    if (registration.eventId && Number(registration.eventId.registeredCount || 0) > 0) {
      registration.eventId.registeredCount = Math.max(
        0,
        Number(registration.eventId.registeredCount || 0) - 1
      );
      await registration.eventId.save();
    }

    transaction.providerStatus = 'REFUNDED';
    transaction.status = 'completed';
    transaction.notes = reason || transaction.notes || 'Event refund after capture';
    await transaction.save();

    await notificationService.createNotification({
      userId: registration.userId,
      type: 'payment_refunded',
      title: 'Event payment refunded',
      message: `${registration.amountPaid} ${registration.currency} was refunded for your event registration.`,
      data: {
        registrationId: registration._id,
        transactionId: transaction._id,
        amount: registration.amountPaid,
        currency: registration.currency,
      },
    });

    return {
      registration,
      transaction,
      refundMode: 'captured_refund',
    };
  }

  throw new Error('This event payment is not in a refundable state');
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
  applySuccessfulFawryTransaction,
  applyFailedFawryTransaction,
  getPaymentStatus,
  verifyFawryTransactionStatus,
  retryFawryCheckout,
  markTransactionRefunded,
  refundMentorSessionPayment,
  refundEventRegistrationPayment,
};