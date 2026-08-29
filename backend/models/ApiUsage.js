const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const ApiUsage = sequelize.define('ApiUsage', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: User,
      key: 'id'
    }
  },
  service: {
    type: DataTypes.STRING, // 'gemini', 'apify', 'meta'
    allowNull: false
  },
  action: {
    type: DataTypes.STRING, // 'post_generation', 'competitor_scrape', 'publish_post' etc.
    allowNull: false
  },
  status: {
    type: DataTypes.STRING, // 'success', 'failed'
    allowNull: false,
    defaultValue: 'success'
  }
}, {
  timestamps: true
});

// Relationships
User.hasMany(ApiUsage, { foreignKey: 'userId', onDelete: 'CASCADE' });
ApiUsage.belongsTo(User, { foreignKey: 'userId' });

module.exports = ApiUsage;
