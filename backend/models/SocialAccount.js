const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const SocialAccount = sequelize.define('SocialAccount', {
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
  platform: {
    type: DataTypes.STRING,
    allowNull: false // 'facebook' or 'instagram'
  },
  accountId: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  accountName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  accessToken: {
    type: DataTypes.TEXT, // Using TEXT since tokens can be long
    allowNull: false
  },
  profilePicture: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true
});

// Relationships
User.hasMany(SocialAccount, { foreignKey: 'userId', onDelete: 'CASCADE' });
SocialAccount.belongsTo(User, { foreignKey: 'userId' });

module.exports = SocialAccount;
