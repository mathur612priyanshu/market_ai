const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const CompetitorWatchlist = sequelize.define('CompetitorWatchlist', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  handle: {
    type: DataTypes.STRING,
    allowNull: true
  },
  rank: {
    type: DataTypes.INTEGER,
    allowNull: true
  }
});

module.exports = CompetitorWatchlist;
