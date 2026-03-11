module.exports = (requiredFields = []) => {
  return (req, res, next) => {
    for (const field of requiredFields) {
      const value = req.body[field];

      if (value === undefined || value === null || value === '') {
        return res.status(400).json({
          success: false,
          message: `${field} is required`,
        });
      }
    }

    next();
  };
};