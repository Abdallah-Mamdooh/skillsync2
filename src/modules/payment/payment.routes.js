const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./payment.controller');
const roleMiddleware = require('../../middlewares/role.middleware');
router.post('/methods', authMiddleware, controller.addPaymentMethod);
router.get('/methods', authMiddleware, controller.listPaymentMethods);

router.post('/wallet/deposit', authMiddleware, controller.depositToWallet);
router.get('/wallet', authMiddleware, controller.getWalletSummary);
router.post('/fawry/checkout', authMiddleware, controller.createFawryCheckout);
router.post('/fawry/webhook', controller.handleFawryWebhook);
router.get('/status/:transactionId', authMiddleware, controller.getPaymentStatus);
router.get('/fawry/status/:transactionId', authMiddleware, controller.verifyFawryTransactionStatus);
router.post('/fawry/retry/:transactionId', authMiddleware, controller.retryFawryCheckout);
router.post('/refund/:transactionId', authMiddleware, controller.markTransactionRefunded);
router.post(
  '/refunds/session/:sessionId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.refundMentorSessionPayment
);



router.post(
  '/refunds/event/:registrationId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.refundEventRegistrationPayment
);

router.get(
  '/mentor/earnings',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMentorEarningsSummary
);

router.post('/paymob/checkout', authMiddleware, controller.createPaymobCheckout);
router.post('/paymob/webhook', controller.handlePaymobWebhook);
module.exports = router;