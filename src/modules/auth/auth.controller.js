const asyncHandler = require('../../middlewares/async.middleware');
const authService = require('./auth.service');

const signup = asyncHandler(async (req, res) => {
  const response = await authService.signup(req.body);
  res.status(201).json(response);
});

const login = asyncHandler(async (req, res) => {
  const response = await authService.login(req.body);
  res.status(200).json(response);
});

const forgotPassword = asyncHandler(async (req, res) => {
  const response = await authService.forgotPassword(req.body.email);
  res.status(200).json(response);
});

const resetPassword = asyncHandler(async (req, res) => {
  const response = await authService.resetPassword(
    req.params.token,
    req.body.newPassword
  );
  res.status(200).json(response);
});

const changePassword = asyncHandler(async (req, res) => {
  const response = await authService.changePassword(
    req.user._id,
    req.body.oldPassword,
    req.body.newPassword
  );
  res.status(200).json(response);
});

const googleLogin = asyncHandler(async (req, res) => {
  const response = await authService.googleLogin(req.body.email);
  res.status(200).json(response);
});
module.exports = {
  signup,
  login,
  forgotPassword,
  resetPassword,
  changePassword,
  googleLogin
};
