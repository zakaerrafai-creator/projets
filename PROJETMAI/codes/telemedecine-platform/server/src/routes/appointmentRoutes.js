const express = require("express");
const {
  createAppointment,
  listMyAppointments,
  updateStatus
} = require("../controllers/appointmentController");
const { authMiddleware } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", authMiddleware, createAppointment);
router.get("/mine", authMiddleware, listMyAppointments);
router.patch("/:id/status", authMiddleware, updateStatus);

module.exports = router;
