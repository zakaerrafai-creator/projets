const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const Joi = require("joi");

const User = require("../models/User");

const registerSchema = Joi.object({
  fullName: Joi.string().min(3).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  role: Joi.string().valid("patient", "doctor", "admin").required(),
  specialty: Joi.string().allow("")
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

async function register(req, res) {
  const { error, value } = registerSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.message });
  }

  const exists = await User.findOne({ email: value.email });
  if (exists) {
    return res.status(409).json({ message: "Email deja utilise" });
  }

  const passwordHash = await bcrypt.hash(value.password, 10);
  const user = await User.create({
    fullName: value.fullName,
    email: value.email,
    passwordHash,
    role: value.role,
    specialty: value.specialty || ""
  });

  return res.status(201).json({
    id: user._id,
    fullName: user.fullName,
    email: user.email,
    role: user.role
  });
}

async function login(req, res) {
  const { error, value } = loginSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.message });
  }

  const user = await User.findOne({ email: value.email });
  if (!user) {
    return res.status(401).json({ message: "Identifiants invalides" });
  }

  const ok = await bcrypt.compare(value.password, user.passwordHash);
  if (!ok) {
    return res.status(401).json({ message: "Identifiants invalides" });
  }

  const token = jwt.sign(
    {
      sub: String(user._id),
      role: user.role,
      fullName: user.fullName
    },
    process.env.JWT_SECRET,
    { expiresIn: "8h" }
  );

  return res.json({
    token,
    user: {
      id: user._id,
      fullName: user.fullName,
      role: user.role,
      email: user.email
    }
  });
}

module.exports = {
  register,
  login
};
