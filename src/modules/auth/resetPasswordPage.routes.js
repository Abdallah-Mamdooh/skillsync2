const express = require('express');

const router = express.Router();

router.get('/reset-password/:token', (req, res) => {
  const token = req.params.token;

  res.type('html').send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Reset Password - SkillSync</title>
  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      background: #f4f6fb;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 20px;
    }
    .card {
      width: 100%;
      max-width: 420px;
      background: white;
      padding: 28px;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.08);
    }
    h2 {
      margin-top: 0;
      text-align: center;
      color: #222;
    }
    p {
      text-align: center;
      color: #666;
      font-size: 14px;
    }
    input {
      width: 100%;
      padding: 14px;
      margin-top: 12px;
      border: 1px solid #ddd;
      border-radius: 10px;
      font-size: 15px;
      box-sizing: border-box;
    }
    button {
      width: 100%;
      margin-top: 18px;
      padding: 14px;
      background: #4f46e5;
      color: white;
      border: none;
      border-radius: 10px;
      font-size: 16px;
      cursor: pointer;
    }
    button:disabled {
      opacity: 0.7;
      cursor: not-allowed;
    }
    .message {
      margin-top: 16px;
      text-align: center;
      font-size: 14px;
    }
    .success {
      color: #0f9d58;
    }
    .error {
      color: #d93025;
    }
  </style>
</head>
<body>
  <div class="card">
    <h2>Reset Password</h2>
    <p>Enter your new SkillSync password below.</p>

    <form id="resetForm">
      <input id="newPassword" type="password" placeholder="New password" required minlength="8" />
      <input id="confirmPassword" type="password" placeholder="Confirm password" required minlength="8" />
      <button id="submitBtn" type="submit">Reset Password</button>
    </form>

    <div id="message" class="message"></div>
  </div>

  <script>
    const form = document.getElementById('resetForm');
    const message = document.getElementById('message');
    const submitBtn = document.getElementById('submitBtn');

    form.addEventListener('submit', async function (e) {
      e.preventDefault();

      const newPassword = document.getElementById('newPassword').value;
      const confirmPassword = document.getElementById('confirmPassword').value;

      message.textContent = '';
      message.className = 'message';

      if (newPassword !== confirmPassword) {
        message.textContent = 'Passwords do not match.';
        message.classList.add('error');
        return;
      }

      if (!/^(?=.*[A-Za-z])(?=.*\\d).{8,}$/.test(newPassword)) {
        message.textContent = 'Password must be at least 8 characters and contain at least one letter and one number.';
        message.classList.add('error');
        return;
      }

      submitBtn.disabled = true;
      submitBtn.textContent = 'Resetting...';

      try {
        const response = await fetch('/api/auth/reset-password/${token}', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ newPassword })
        });

        const result = await response.json();

        if (!response.ok || !result.success) {
          throw new Error(result.message || 'Failed to reset password.');
        }

        message.textContent = 'Password reset successfully. You can now return to the app and log in.';
        message.classList.add('success');
        form.reset();
      } catch (error) {
        message.textContent = error.message;
        message.classList.add('error');
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Reset Password';
      }
    });
  </script>
</body>
</html>
  `);
});

module.exports = router;