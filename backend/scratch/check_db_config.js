const sequelize = require('../config/db');
const SystemConfig = require('../models/SystemConfig');

async function checkConfigs() {
  try {
    await sequelize.authenticate();
    console.log('Database connected.');
    const configs = await SystemConfig.findAll();
    console.log('--- ALL SYSTEM CONFIGURATIONS ---');
    configs.forEach(c => {
      console.log(` - Key: "${c.key}", Value: "${c.value}" (Type of value: ${typeof c.value})`);
    });
    console.log('---------------------------------');
    process.exit(0);
  } catch (error) {
    console.error('Error querying system configs:', error.message);
    process.exit(1);
  }
}

checkConfigs();
