const Joi = require("joi");
const Appointment = require("../models/Appointment");

const createSchema = Joi.object({
  doctorId: Joi.string().required(),
  scheduledAt: Joi.date().iso().required(),
  reason: Joi.string().allow("")
});

async function createAppointment(req, res) {
  const { error, value } = createSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.message });
  }

  const appointment = await Appointment.create({
    patientId: req.user.sub,
    doctorId: value.doctorId,
    scheduledAt: value.scheduledAt,
    reason: value.reason || ""
  });

  return res.status(201).json(appointment);
}

async function listMyAppointments(req, res) {
  const filter = req.user.role === "doctor" ? { doctorId: req.user.sub } : { patientId: req.user.sub };
  const list = await Appointment.find(filter)
    .populate("doctorId", "fullName specialty")
    .populate("patientId", "fullName")
    .sort({ scheduledAt: 1 });

  return res.json(list);
}

async function updateStatus(req, res) {
  const schema = Joi.object({
    status: Joi.string().valid("pending", "confirmed", "completed", "cancelled").required()
  });

  const { error, value } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.message });
  }

  const appointment = await Appointment.findById(req.params.id);
  if (!appointment) {
    return res.status(404).json({ message: "Rendez-vous introuvable" });
  }

  const ownsAppointment =
    String(appointment.patientId) === req.user.sub || String(appointment.doctorId) === req.user.sub;

  if (!ownsAppointment && req.user.role !== "admin") {
    return res.status(403).json({ message: "Acces refuse" });
  }

  appointment.status = value.status;
  await appointment.save();

  return res.json(appointment);
}

module.exports = {
  createAppointment,
  listMyAppointments,
  updateStatus
};
