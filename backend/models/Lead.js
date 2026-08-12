const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const Lead = sequelize.define('Lead', {
  id: {
    type: DataTypes.STRING,
    primaryKey: true
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id'
    }
  },
  formId: {
    type: DataTypes.STRING,
    allowNull: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('New', 'Contacted', 'Converted'),
    defaultValue: 'New',
    allowNull: false
  },
  submittedAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  fieldData: {
    type: DataTypes.JSON,
    allowNull: true
  }
}, {
  timestamps: true
});

// Relationships
User.hasMany(Lead, { foreignKey: 'userId', onDelete: 'CASCADE' });
Lead.belongsTo(User, { foreignKey: 'userId' });

module.exports = Lead;
