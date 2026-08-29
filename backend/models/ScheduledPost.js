const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const ScheduledPost = sequelize.define('ScheduledPost', {
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
  caption: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  hashtags: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  mediaUrl: {
    type: DataTypes.STRING,
    allowNull: true
  },
  scheduledTime: {
    type: DataTypes.DATE,
    allowNull: false
  },
  status: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'pending' // 'pending', 'published', 'failed'
  },
  errorMessage: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  prompt: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  tone: {
    type: DataTypes.STRING,
    allowNull: true
  },
  type: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true
});

// Relationships
User.hasMany(ScheduledPost, { foreignKey: 'userId', onDelete: 'CASCADE' });
ScheduledPost.belongsTo(User, { foreignKey: 'userId' });

module.exports = ScheduledPost;
