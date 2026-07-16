const express = require("express");
const { createRecord, listRecordsForPatient } = require("../controllers/recordController");
const { authMiddleware, allowRoles } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", authMiddleware, allowRoles("doctor", "admin"), createRecord);
router.get("/patient/:patientId", authMiddleware, listRecordsForPatient);
router.get("/me", authMiddleware, listRecordsForPatient);

module.exports = router;
