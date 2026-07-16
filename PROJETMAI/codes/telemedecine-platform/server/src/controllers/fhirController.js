const User = require("../models/User");
const MedicalRecord = require("../models/MedicalRecord");
const { getSnomedCoding, LOINC_VITAL_SIGNS, buildVitalObservation } = require("../utils/fhirCoding");

async function exportPatientBundle(req, res) {
  const patient = await User.findById(req.params.patientId);
  if (!patient || patient.role !== "patient") {
    return res.status(404).json({ message: "Patient introuvable" });
  }

  const records = await MedicalRecord.find({ patientId: patient._id }).populate("doctorId", "fullName");

  // Ressource Patient FHIR R4
  const patientResource = {
    resource: {
      resourceType: "Patient",
      id: String(patient._id),
      name: [{ use: "official", text: patient.fullName }],
      telecom: [{ system: "email", value: patient.email, use: "home" }]
    }
  };

  // Ressources Condition avec codification SNOMED CT
  const conditionEntries = records.map((record) => {
    const snomedCoding = record.snomedCode
      ? { system: "http://snomed.info/sct", code: record.snomedCode, display: record.diagnosis }
      : getSnomedCoding(record.diagnosis);

    return {
      resource: {
        resourceType: "Condition",
        id: String(record._id),
        clinicalStatus: {
          coding: [{ system: "http://terminology.hl7.org/CodeSystem/condition-clinical", code: "active" }]
        },
        subject: { reference: `Patient/${patient._id}` },
        recorder: { display: record.doctorId?.fullName || "Medecin" },
        code: {
          coding: [snomedCoding],
          text: record.diagnosis
        },
        note: record.notes ? [{ text: record.notes }] : [],
        recordedDate: record.createdAt
      }
    };
  });

  // Ressources Observation avec codes LOINC (signes vitaux d'exemple)
  const observationEntries = LOINC_VITAL_SIGNS.map((vs, idx) => ({
    resource: buildVitalObservation(String(patient._id), vs, `${String(patient._id)}-${idx}`)
  }));

  const bundle = {
    resourceType: "Bundle",
    id: `bundle-${String(patient._id)}`,
    type: "collection",
    timestamp: new Date().toISOString(),
    entry: [patientResource, ...conditionEntries, ...observationEntries]
  };

  return res.json(bundle);
}

module.exports = {
  exportPatientBundle
};
