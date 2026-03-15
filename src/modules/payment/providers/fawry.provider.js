const crypto = require('crypto');

function getFawryConfig() {
  const merchantCode = process.env.FAWRY_MERCHANT_CODE;
  const securityKey = process.env.FAWRY_SECURITY_KEY;

  const baseUrl =
    process.env.FAWRY_BASE_URL ||
    'https://atfawry.fawrystaging.com/fawrypay-api/api/payments';

  if (!merchantCode || !securityKey) {
    throw new Error('Fawry configuration is missing');
  }

  return {
    merchantCode,
    securityKey,
    baseUrl,
  };
}

function formatAmount(amount) {
  return Number(amount || 0).toFixed(2);
}

function generateMerchantRef(prefix = 'txn') {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 1000000)}`;
}

/**
 * MVP simplified signature helper.
 * We are preparing the provider file first.
 * We will refine the exact request payload/signature in the next step
 * when we build the actual checkout request function.
 */
function generateBasicSignature({
  merchantCode,
  merchantRefNum,
  customerProfileId = '',
  returnUrl = '',
  itemId = '',
  quantity = 1,
  price = 0,
  securityKey,
}) {
  const raw =
    `${merchantCode}` +
    `${merchantRefNum}` +
    `${customerProfileId}` +
    `${returnUrl}` +
    `${itemId}` +
    `${quantity}` +
    `${formatAmount(price)}` +
    `${securityKey}`;

  return crypto.createHash('sha256').update(raw).digest('hex');
}

function buildHostedCheckoutPayload({
  merchantRefNum,
  customerProfileId,
  customerName,
  customerEmail,
  customerMobile,
  amount,
  description,
  returnUrl,
  paymentMethod = '',
}) {
  const { merchantCode, securityKey } = getFawryConfig();

  const chargeItem = {
    itemId: merchantRefNum,
    description: description || 'SkillSync payment',
    price: formatAmount(amount),
    quantity: 1,
  };

  const signature = generateBasicSignature({
    merchantCode,
    merchantRefNum,
    customerProfileId,
    returnUrl,
    itemId: chargeItem.itemId,
    quantity: chargeItem.quantity,
    price: chargeItem.price,
    securityKey,
  });

  return {
    merchantCode,
    merchantRefNum,
    customerProfileId: String(customerProfileId || ''),
    customerName: customerName || '',
    customerEmail: customerEmail || '',
    customerMobile: customerMobile || '',
    paymentMethod,
    returnUrl: returnUrl || '',
    chargeItems: [chargeItem],
    signature,
  };
}

module.exports = {
  getFawryConfig,
  formatAmount,
  generateMerchantRef,
  generateBasicSignature,
  buildHostedCheckoutPayload,
};