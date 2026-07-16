const express = require("express");
const { exportPatientBundle } = require("../controllers/fhirController");
const { authMiddleware, allowRoles } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/patients/:patientId/bundle", authMiddleware, allowRoles("doctor", "admin"), exportPatientBundle);

module.exports = router;
