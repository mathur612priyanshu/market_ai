const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const CompetitorAd = sequelize.define('CompetitorAd', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  watchlistId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  caption: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  mediaType: {
    type: DataTypes.STRING,
    allowNull: false
  },
  mediaUrl: {
    type: DataTypes.STRING,
    allowNull: true
  },
  landingPageUrl: {
    type: DataTypes.STRING,
    allowNull: true
  },
  ctaText: {
    type: DataTypes.STRING,
    allowNull: true
  },
  startedAt: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  adHook: {
    type: DataTypes.STRING,
    allowNull: true
  },
  angle: {
    type: DataTypes.STRING,
    allowNull: true
  },
  offer: {
    type: DataTypes.STRING,
    allowNull: true
  }
});

module.exports = CompetitorAd;
