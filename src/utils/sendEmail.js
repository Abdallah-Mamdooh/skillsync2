const nodemailer = require('nodemailer');
const dns = require('dns');

try {
  dns.setDefaultResultOrder('ipv4first');
} catch (error) {
  console.warn('Could not force IPv4 DNS order:', error.message);
}

const sendEmail = async (to, subject, html) => {
  const emailUser = String(process.env.EMAIL_USER || '').trim();
  const emailPass = String(process.env.EMAIL_PASS || '').replace(/\s/g, '');

  if (!emailUser || !emailPass) {
    throw new Error('Email service is not configured. EMAIL_USER or EMAIL_PASS is missing.');
  }

  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    family: 4,
    auth: {
      user: emailUser,
      pass: emailPass,
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