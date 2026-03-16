const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./payment.controller');

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
module.exports = router;