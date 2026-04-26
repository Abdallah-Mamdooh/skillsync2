const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const controller = require('./payout.controller');

// mentor side
router.post(
  '/methods',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.addPayoutMethod
);

router.get(
  '/methods',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.listPayoutMethods
);

router.post(
  '/withdrawals',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.requestWithdrawal
);

router.get(
  '/withdrawals/me',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.listMyWithdrawalRequests
);

// admin side
router.get(
  '/withdrawals',
  authMiddleware,
  roleMiddleware('admin'),
  controller.listAllWithdrawalRequests
);

router.post(
  '/withdrawals/:withdrawalRequestId/approve',
  authMiddleware,
  roleMiddleware('admin'),
  controller.approveWithdrawalRequest
);

router.post(
  '/withdrawals/:withdrawalRequestId/reject',
  authMiddleware,
  roleMiddleware('admin'),
  controller.rejectWithdrawalRequest
);

router.post(
  '/withdrawals/:withdrawalRequestId/mark-paid',
  authMiddleware,
  roleMiddleware('admin'),
  controller.markWithdrawalRequestPaid
);

router.post(
  '/withdrawals/:withdrawalRequestId/cancel',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.cancelMyWithdrawalRequest
);

module.exports = router;