async function testSave() {
  try {
    console.log('Logging in as Admin...');
    const loginRes = await fetch('http://localhost:5001/api/admin/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: 'admin@marketai.com',
        password: 'Admin@12345'
      })
    });
    
    const loginData = await loginRes.json();
    if (!loginData.success) {
      console.error('Login failed:', loginData.message);
      process.exit(1);
    }
    const token = loginData.token;
    console.log('Login successful. Token obtained.');

    console.log('\nSending custom costs configuration update to backend...');
    
    // Simulate updating gemini_cost to 0.025, apify to 0.15, etc.
    const saveRes = await fetch('http://localhost:5001/api/plans/config', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        gemini_cost: '0.025',
        apify_cost: '0.15',
        meta_cost: '0.008',
        gemini_limit: '500'
      })
    });

    const saveData = await saveRes.json();
    console.log('Save response from server:', saveData);

    console.log('\nFetching configs back to verify persistence...');
    const getRes = await fetch('http://localhost:5001/api/plans/config', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    const getData = await getRes.json();
    
    console.log('Get response from server (verified values):');
    console.log(` - gemini_cost: ${getData.config.gemini_cost} (Type: ${typeof getData.config.gemini_cost}, Expected: 0.025)`);
    console.log(` - apify_cost: ${getData.config.apify_cost} (Type: ${typeof getData.config.apify_cost}, Expected: 0.15)`);
    console.log(` - meta_cost: ${getData.config.meta_cost} (Type: ${typeof getData.config.meta_cost}, Expected: 0.008)`);
    console.log(` - gemini_limit: ${getData.config.gemini_limit} (Type: ${typeof getData.config.gemini_limit}, Expected: 500)`);

    if (getData.config.gemini_cost === 0.025) {
      console.log('\n--- VERIFICATION SUCCESS: PERSISTED SUCCESSFULLY ---');
      process.exit(0);
    } else {
      console.log('\n--- VERIFICATION FAILED ---');
      process.exit(1);
    }
  } catch (error) {
    console.error('Test script error:', error.message);
    process.exit(1);
  }
}

testSave();
