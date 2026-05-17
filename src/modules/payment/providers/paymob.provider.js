function getPaymobConfig() {
  const secretKey = process.env.PAYMOB_SECRET_KEY;
  const publicKey = process.env.PAYMOB_PUBLIC_KEY;

  const baseUrl =
    process.env.PAYMOB_BASE_URL || 'https://accept.paymob.com';

  const unifiedCheckoutUrl =
    process.env.PAYMOB_UNIFIED_CHECKOUT_URL ||
    'https://accept.paymob.com/unifiedcheckout/';

  if (!secretKey || !publicKey) {
    throw new Error('Paymob configuration is missing');
  }

  return {
    secretKey,
    publicKey,
    baseUrl,
    unifiedCheckoutUrl,
  };
}

function buildPaymobIntentionPayload({
  amount,
  currency = 'EGP',
  paymentMethods = [],
  merchantOrderId,
  customer,
  items = [],
  extras = {},
}) {
  if (!amount || Number(amount) <= 0) {
    throw new Error('Amount must be greater than 0');
  }

  if (!paymentMethods.length) {
    throw new Error('At least one Paymob payment method/integration ID is required');
  }

  return {
    amount: Math.round(Number(amount) * 100),
    currency,
    payment_methods: paymentMethods.map((id) => Number(id)),
    merchant_order_id: merchantOrderId,
    billing_data: {
      first_name: customer?.firstName || customer?.name || 'SkillSync',
      last_name: customer?.lastName || 'User',
      email: customer?.email || 'customer@skillsync.com',
      phone_number: customer?.phoneNumber || customer?.phone || '01000000000',
      apartment: 'NA',
      floor: 'NA',
      street: 'NA',
      building: 'NA',
      shipping_method: 'NA',
      postal_code: 'NA',
      city: 'Cairo',
      country: 'EG',
      state: 'Cairo',
    },
    items,
    extras,
  };
}

function buildUnifiedCheckoutUrl(clientSecret) {
  const { publicKey, unifiedCheckoutUrl } = getPaymobConfig();

  if (!clientSecret) {
    throw new Error('Paymob client_secret is required');
  }

  const url = new URL(unifiedCheckoutUrl);
  url.searchParams.set('publicKey', publicKey);
  url.searchParams.set('clientSecret', clientSecret);

  return url.toString();
}

module.exports = {
  getPaymobConfig,
  buildPaymobIntentionPayload,
  buildUnifiedCheckoutUrl,
};