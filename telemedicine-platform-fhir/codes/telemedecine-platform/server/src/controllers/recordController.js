const Joi = require("joi");
const MedicalRecord = require("../models/MedicalRecord");

const createSchema = Joi.object({
  patientId: Joi.string().required(),
  diagnosis: Joi.string().required(),
  snomedCode: Joi.string().allow(""),
  notes: Joi.string().allow(""),
  prescription: Joi.string().allow("")
});

async function createRecord(req, res) {
  const { error, value } = createSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: error.message });
  }

  const record = await MedicalRecord.create({
    patientId: value.patientId,
    doctorId: req.user.sub,
    diagnosis: value.diagnosis,
    snomedCode: value.snomedCode || "",
    notes: value.notes || "",
    prescription: value.prescription || ""
  });

  return res.status(201).json(record);
}

async function listRecordsForPatient(req, res) {
  const patientId = req.params.patientId || req.user.sub;
  const canRead = req.user.role === "doctor" || req.user.role === "admin" || req.user.sub === patientId;

  if (!canRead) {
    return res.status(403).json({ message: "Acces refuse" });
  }

  const records = await MedicalRecord.find({ patientId })
    .populate("doctorId", "fullName specialty")
    .sort({ createdAt: -1 });

  return res.json(records);
}

module.exports = {
  createRecord,
  listRecordsForPatient
};
