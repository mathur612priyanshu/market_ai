const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/', authMiddleware, reportController.listReports);
router.get('/:type', authMiddleware, reportController.getReportDetails);
router.get('/:type/download', authMiddleware, reportController.downloadReport);

module.exports = router;
