require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const diagnoseRoutes = require('./routes/diagnose');
const dealerRoutes = require('./routes/dealers');
const farmerRoutes = require('./routes/farmers');
const agronomistRoutes = require('./routes/agronomists');
const governmentRoutes = require('./routes/government');
const agrovetRoutes = require('./routes/agrovets');
const saccoRoutes = require('./routes/saccos');
const insuranceRoutes = require('./routes/insurance');
const consultationRoutes = require('./routes/consultations');
const messageRoutes = require('./routes/messages');
const notificationRoutes = require('./routes/notifications');
const caseRoutes = require('./routes/cases');
const searchRoutes = require('./routes/search');
const adminRoutes = require('./routes/admin');

const app = express();
const PORT = process.env.PORT || 3000;
const allowedOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    if (process.env.NODE_ENV !== 'production' || !origin) {
      return callback(null, true);
    }

    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    return callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later.' }
});
app.use(limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

app.get('/', (req, res) => {
  res.status(200).json({
    name: 'ShambaDoc API',
    status: 'online',
    health: '/health',
    version: '1.0.0'
  });
});

app.use('/api/diagnose', diagnoseRoutes);
app.use('/api/dealers', dealerRoutes);
app.use('/api/farmers', farmerRoutes);
app.use('/api/agronomists', agronomistRoutes);
app.use('/api/government', governmentRoutes);
app.use('/api/agrovets', agrovetRoutes);
app.use('/api/saccos', saccoRoutes);
app.use('/api/insurance', insuranceRoutes);
app.use('/api/consultations', consultationRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/cases', caseRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/admin', adminRoutes);

app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.listen(PORT, () => {
  console.log(`ShambaDoc API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
