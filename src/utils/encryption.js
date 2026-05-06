const crypto = require('crypto');

const algorithm = 'aes-256-gcm';

const getKey = () => {
  const key = process.env.PAYOUT_ENCRYPTION_KEY;

  if (!key || key.length !== 64) {
    throw new Error('Invalid PAYOUT_ENCRYPTION_KEY. It must be 64 hex characters.');
  }

  return Buffer.from(key, 'hex');
};

const encryptText = (text) => {
  if (!text) return null;

  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(algorithm, getKey(), iv);

  const encrypted = Buffer.concat([
    cipher.update(text, 'utf8'),
    cipher.final(),
  ]);

  const authTag = cipher.getAuthTag();

  return {
    iv: iv.toString('hex'),
    content: encrypted.toString('hex'),
    authTag: authTag.toString('hex'),
  };
};

const decryptText = (encryptedData) => {
  if (!encryptedData?.iv || !encryptedData?.content || !encryptedData?.authTag) {
    return null;
  }

  const decipher = crypto.createDecipheriv(
    algorithm,
    getKey(),
    Buffer.from(encryptedData.iv, 'hex')
  );

  decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));

  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(encryptedData.content, 'hex')),
    decipher.final(),
  ]);

  return decrypted.toString('utf8');
};

module.exports = {
  encryptText,
  decryptText,
};