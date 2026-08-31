const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const RechargeHistory = sequelize.define('RechargeHistory', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id'
    }
  },
  planName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  days: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  status: {
    type: DataTypes.STRING,
    defaultValue: 'completed'
  },
  paymentGateway: {
    type: DataTypes.STRING,
    defaultValue: 'Razorpay'
  },
  transactionId: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true
});

// Relationships
User.hasMany(RechargeHistory, { foreignKey: 'userId', onDelete: 'CASCADE' });
RechargeHistory.belongsTo(User, { foreignKey: 'userId' });

module.exports = RechargeHistory;
