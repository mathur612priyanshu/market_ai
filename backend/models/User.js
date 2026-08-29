const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true
  },
  industry: {
    type: DataTypes.STRING,
    allowNull: true
  },
  country: {
    type: DataTypes.STRING,
    allowNull: true
  },
  profilePicture: {
    type: DataTypes.STRING,
    allowNull: true
  },
  businessName: {
    type: DataTypes.STRING,
    allowNull: true
  },
  businessAddress: {
    type: DataTypes.STRING,
    allowNull: true
  },
  businessWebsite: {
    type: DataTypes.STRING,
    allowNull: true
  },
  businessServices: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  businessLogo: {
    type: DataTypes.STRING,
    allowNull: true
  },
  plan: {
    type: DataTypes.STRING,
    defaultValue: 'Free'
  },
  status: {
    type: DataTypes.STRING,
    defaultValue: 'active'
  }
}, {
  timestamps: true
});

module.exports = User;
