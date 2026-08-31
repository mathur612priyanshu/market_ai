const sequelize = require('../config/db');

async function checkIndexes() {
  try {
    const [results] = await sequelize.query('SHOW INDEX FROM RechargeHistories');
    console.log('INDEXES ON RechargeHistories:');
    console.log(JSON.stringify(results, null, 2));

    const [columns] = await sequelize.query('DESCRIBE RechargeHistories');
    console.log('\nCOLUMNS OF RechargeHistories:');
    console.log(JSON.stringify(columns, null, 2));
  } catch (error) {
    console.error('Error querying database:', error);
  } finally {
    process.exit(0);
  }
}

checkIndexes();
