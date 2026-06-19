const nodemailer = require('nodemailer');
const dns = require('dns').promises;

const SMTP_HOST = 'smtp.gmail.com';

const sendEmail = async (to, subject, html) => {
  const emailUser = String(process.env.EMAIL_USER || '').trim();
  const emailPass = String(process.env.EMAIL_PASS || '').replace(/\s/g, '');

  if (!emailUser || !emailPass) {
    throw new Error('Email service is not configured. EMAIL_USER or EMAIL_PASS is missing.');
  }

  let smtpHost = SMTP_HOST;

  try {
    const ipv4Addresses = await dns.resolve4(SMTP_HOST);

    if (ipv4Addresses && ipv4Addresses.length > 0) {
      smtpHost = ipv4Addresses[0];
    }

    console.log('SMTP Gmail IPv4 selected:', smtpHost);
  } catch (error) {
    console.warn('Could not resolve Gmail IPv4, using hostname:', error.message);
  }

  const transporter = nodemailer.createTransport({
    host: smtpHost,
    port: 465,
    secure: true,
    auth: {
      user: emailUser,
      pass: emailPass,
    },
    tls: {
      servername: SMTP_HOST,
      rejectUnauthorized: true,
    },
    connectionTimeout: 20000,
    greetingTimeout: 20000,
    socketTimeout: 30000,
  });

  try {
    await transporter.verify();

    const info = await transporter.sendMail({
      from: `"SkillSync" <${emailUser}>`,
      to,
      subject,
      html,
      text: String(html || '').replace(/<[^>]*>/g, ''),
    });

    console.log('Email sent successfully:', {
      to,
      subject,
      messageId: info.messageId,
    });

    return info;
  } catch (error) {
    console.error('Email sending failed:', {
      to,
      subject,
      message: error.message,
      code: error.code,
      command: error.command,
      response: error.response,
    });

    throw new Error(`Email sending failed: ${error.message}`);
  }
};

module.exports = sendEmail;