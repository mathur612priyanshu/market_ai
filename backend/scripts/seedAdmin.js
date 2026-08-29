const bcrypt = require('bcryptjs');
const sequelize = require('../config/db');
const Admin = require('../models/Admin');

async function seed() {
  try {
    // Force/Alter table sync to make sure Admin table is created
    console.log('Syncing database...');
    await sequelize.sync();

    const email = 'admin@marketai.com';
    const password = 'Admin@12345';
    
    // Check if admin already exists
    const existingAdmin = await Admin.findOne({ where: { email } });
    if (existingAdmin) {
      console.log(`Admin account for ${email} already exists.`);
      process.exit(0);
    }

    console.log('Hashing password...');
    const hashedPassword = await bcrypt.hash(password, 10);

    console.log('Creating Admin record...');
    await Admin.create({
      name: 'Super Admin',
      email: email,
      password: hashedPassword,
      role: 'super_admin',
      status: 'active'
    });

    console.log('Seeding completed successfully!');
    console.log('---------------------------------');
    console.log(`Email: ${email}`);
    console.log(`Password: ${password}`);
    console.log('---------------------------------');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding admin:', error);
    process.exit(1);
  }
}

seed();
