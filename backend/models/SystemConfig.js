const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const SystemConfig = sequelize.define('SystemConfig', {
  key: {
    type: DataTypes.STRING,
    primaryKey: true
  },
  value: {
    type: DataTypes.STRING,
    allowNull: false
  }
}, {
  timestamps: true
});

module.exports = SystemConfig;
