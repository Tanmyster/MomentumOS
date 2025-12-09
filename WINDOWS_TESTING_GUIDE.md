# Testing MomentumOS on Windows

**Guide for Windows Developers**  
**Date**: December 9, 2025

---

## 🖥️ Overview: Testing Options on Windows

Since MomentumOS is a Swift/iOS app, you have **3 main options** on Windows:

| Option | Cost | Difficulty | Best For |
|--------|------|-----------|----------|
| **VM Parallels/Fusion** | $$ | Medium | Full testing |
| **iCloud.com Simulator** | Free | Easy | Quick checks |
| **Backend Testing** | Free | Easy | API testing |
| **Remote Mac** | $$$ | Easy | Real device |

---

## 🔧 Option 1: Test Backend Only (Easiest - 15 minutes)

Since the backend is Node.js, you can test it completely on Windows.

### Step 1: Install Prerequisites
```bash
# Install Node.js from https://nodejs.org/ (v16+)
# Verify installation
node --version
npm --version

# Install PostgreSQL from https://www.postgresql.org/
# Add to PATH during installation
psql --version
```

### Step 2: Start the Backend

```bash
cd backend

# Install dependencies
npm install

# Create .env file (copy from .env.example)
copy .env.example .env

# Edit .env with your settings (optional for local testing)
# Default PostgreSQL should work: postgresql://postgres:password@localhost:5432/momentumos

# Create database
createdb momentumos

# Initialize schema
psql -d momentumos -f database.sql

# Start server
npm start
```

**Server running at**: `http://localhost:3000`

### Step 3: Test API Endpoints

**Using PowerShell:**
```powershell
# Test health check
curl http://localhost:3000/v1/health

# Test registration
$body = @{
    email = "test@example.com"
    password = "TestPassword123"
    name = "Test User"
} | ConvertTo-Json

curl -X POST http://localhost:3000/v1/auth/register `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body

# Test login
$loginBody = @{
    email = "test@example.com"
    password = "TestPassword123"
} | ConvertTo-Json

$response = curl -X POST http://localhost:3000/v1/auth/login `
  -Headers @{"Content-Type"="application/json"} `
  -Body $loginBody -PassThrough

# Extract token for further requests
$token = ($response | ConvertFrom-Json).accessToken
echo "Token: $token"

# Test getting user profile (requires token)
curl -X GET http://localhost:3000/v1/users/me `
  -Headers @{"Authorization"="Bearer $token"}
```

**Using Git Bash (easier):**
```bash
# Test health
curl http://localhost:3000/v1/health

# Register
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "password":"TestPassword123",
    "name":"Test User"
  }'

# Login
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "password":"TestPassword123"
  }'

# Get profile (replace TOKEN with actual token)
curl -X GET http://localhost:3000/v1/users/me \
  -H "Authorization: Bearer TOKEN"
```

### Step 4: Test Database

```bash
# Connect to database
psql -d momentumos

# Check tables
\dt

# View users table
SELECT * FROM users;

# View habits table
SELECT * FROM habits;

# Exit
\q
```

**✅ Backend testing complete!**

---

## 📱 Option 2: Use Mac in Cloud (15 minutes setup)

### MacStadium (Best Option)
```bash
# 1. Sign up at https://www.macstadium.com/
# 2. Rent hourly Mac access ($3-5/hour)
# 3. Install Xcode
# 4. Clone your repo
# 5. Open MomentumOS/Package.swift in Xcode
# 6. Build and test
```

### GitHub Actions Virtual Mac (Free)
```bash
# Free tier includes macOS runners for public repos
# Push to GitHub, tests run automatically
```

---

## 💻 Option 3: Virtual Machine (45 minutes setup)

### Using Parallels Desktop (Paid - $100)
1. Install Parallels Desktop on Windows
2. Create macOS VM
3. Install Xcode
4. Clone repository
5. Build and test

### Using UTM (Free - Slower)
```bash
# 1. Download UTM from https://mac.getutm.app/
# 2. Download macOS ISO (requires Apple ID)
# 3. Create VM (8GB+ RAM recommended)
# 4. Install Xcode
# 5. Test app
```

---

## 🧪 Option 4: Comprehensive Testing on Windows

### Test Files You Can Review

```bash
cd Sources/MomentumOS

# View main app structure
cat MomentumOS.swift | head -50

# View data models
cat Data/Models.swift | head -100

# View services
cat Services/BackendAPIService.swift
```

### Test Backend + API Integration

Create a test file: `test_api.js`

```javascript
const axios = require('axios');

const API_URL = 'http://localhost:3000/v1';

async function runTests() {
  try {
    console.log('🧪 Testing MomentumOS API...\n');

    // Test 1: Health check
    console.log('1️⃣ Health Check');
    const health = await axios.get(`${API_URL}/health`);
    console.log('✅ Server is healthy:', health.data);

    // Test 2: Register user
    console.log('\n2️⃣ Register User');
    const registerRes = await axios.post(`${API_URL}/auth/register`, {
      email: `user${Date.now()}@test.com`,
      password: 'TestPassword123',
      name: 'Test User'
    });
    console.log('✅ User registered');
    const token = registerRes.data.accessToken;
    console.log('Token:', token.substring(0, 20) + '...');

    // Test 3: Get user profile
    console.log('\n3️⃣ Get User Profile');
    const profileRes = await axios.get(`${API_URL}/users/me`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Profile:', profileRes.data.name);

    // Test 4: Create habit
    console.log('\n4️⃣ Create Habit');
    const habitRes = await axios.post(`${API_URL}/habits`, {
      id: require('uuid').v4(),
      name: 'Morning Run',
      category: 'fitness',
      frequency: 'daily',
      icon: 'figure.run',
      color: 'blue'
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Habit created:', habitRes.data.name);

    // Test 5: Log mood
    console.log('\n5️⃣ Log Mood');
    const moodRes = await axios.post(`${API_URL}/moods`, {
      id: require('uuid').v4(),
      level: 'good',
      energy: 7,
      stress: 3,
      sleep: 8,
      triggers: [],
      notes: 'Feeling great!',
      date: new Date().toISOString()
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Mood logged');

    // Test 6: Create workout
    console.log('\n6️⃣ Create Workout');
    const workoutRes = await axios.post(`${API_URL}/workouts`, {
      id: require('uuid').v4(),
      type: 'strength',
      intensity: 'moderate',
      duration: 45,
      exercises: [],
      estimatedCalories: 300,
      date: new Date().toISOString()
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Workout created');

    // Test 7: Get stats
    console.log('\n7️⃣ Get Statistics');
    const statsRes = await axios.get(`${API_URL}/moods/stats`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Mood stats:', statsRes.data);

    console.log('\n✅ All tests passed!');
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

runTests();
```

**Run the test:**
```bash
cd backend
npm install uuid  # Add uuid if not installed
node ../test_api.js
```

---

## 🔍 Detailed Windows Testing Checklist

### Backend Testing
- [ ] Server starts without errors
- [ ] Database connection successful
- [ ] Health endpoint responds
- [ ] Registration works
- [ ] Login returns token
- [ ] User profile endpoint works
- [ ] Token refresh works
- [ ] Create habit endpoint works
- [ ] Log mood endpoint works
- [ ] Create workout endpoint works
- [ ] Get statistics works
- [ ] Sync endpoint works

### Code Review (Without Running)
- [ ] Swift syntax is correct (review files)
- [ ] All imports are valid
- [ ] Data models are complete
- [ ] Views are well-structured
- [ ] Error handling is comprehensive
- [ ] Animations are defined
- [ ] HealthKit integration code looks correct
- [ ] Siri Shortcuts code is valid
- [ ] WidgetKit code is proper
- [ ] Analytics views are complete

### Documentation
- [ ] README.md is clear
- [ ] DEPLOYMENT_GUIDE.md is complete
- [ ] API endpoints documented
- [ ] Setup instructions included
- [ ] Troubleshooting guide provided

---

## 🎬 Test Scenarios

### Scenario 1: Full User Journey
```
1. User registers
2. User logs in
3. User creates a habit
4. User logs mood
5. User creates workout
6. User logs meal
7. User views stats
8. User syncs data
```

**Test with this script:** (save as `test_journey.js`)

```javascript
// ... (full test script implementation)
// Tests complete user journey through API
```

### Scenario 2: Error Handling
```
1. Invalid email format
2. Wrong password
3. Missing required fields
4. Invalid token
5. Database errors
```

### Scenario 3: Performance
```
1. Measure API response times
2. Check database query performance
3. Verify no memory leaks
4. Check error logs
```

---

## 📊 Testing Tools on Windows

### 1. Postman (GUI - Free)
```bash
# Download from https://www.postman.com/
# Import API endpoints
# Test each endpoint visually
# Save test collections
```

### 2. Insomnia (Alternative - Free)
```bash
# Download from https://insomnia.rest/
# Similar to Postman
# Test REST APIs
```

### 3. VS Code Extension: REST Client
```bash
# Install in VS Code
# Create requests.http file
# Run requests inline
```

### 4. Command Line: curl or Invoke-WebRequest
```powershell
# Built into Windows
# Test APIs from PowerShell
# Automate test scripts
```

---

## 📋 Complete Testing Workflow

### Phase 1: Setup (15 minutes)
1. Install Node.js
2. Install PostgreSQL
3. Clone repository
4. Install dependencies

### Phase 2: Database Setup (10 minutes)
1. Create database
2. Run migrations
3. Verify tables exist
4. Check indexes

### Phase 3: API Testing (30 minutes)
1. Start backend server
2. Test each endpoint
3. Verify responses
4. Check error handling

### Phase 4: Code Review (1 hour)
1. Review Swift code structure
2. Check error handling
3. Verify security practices
4. Review API integration

### Phase 5: Documentation Review (30 minutes)
1. Check README
2. Verify deployment guide
3. Review API docs
4. Check troubleshooting

**Total: ~2.5 hours for comprehensive testing**

---

## 🐛 Common Issues & Solutions

### Issue: PostgreSQL not found
```powershell
# Solution: Add to PATH
$env:Path += ";C:\Program Files\PostgreSQL\15\bin"
# Or reinstall PostgreSQL and check "Add to PATH"
```

### Issue: Port 3000 already in use
```powershell
# Find process using port
netstat -ano | findstr :3000

# Kill process (replace PID)
taskkill /PID <PID> /F

# Or use different port
$env:PORT=3001
npm start
```

### Issue: Database connection failed
```bash
# Check PostgreSQL is running
psql --version

# Start PostgreSQL service (Windows)
# Services app > PostgreSQL > Start

# Test connection
psql -U postgres -h localhost
```

### Issue: npm install fails
```bash
# Clear npm cache
npm cache clean --force

# Try again
npm install

# Or use yarn
npm install -g yarn
yarn install
```

---

## ✅ Final Testing Checklist

- [ ] Backend compiles without errors
- [ ] Database initializes successfully
- [ ] Server starts on port 3000
- [ ] Health check endpoint responds
- [ ] User registration works
- [ ] User login works
- [ ] Authentication token is valid
- [ ] All API endpoints respond
- [ ] Error handling works
- [ ] Database queries complete successfully
- [ ] Code review shows no issues
- [ ] Documentation is complete
- [ ] Ready for deployment

---

## 🎯 Next Steps After Testing

1. **Deploy Backend** (see DEPLOYMENT_GUIDE.md)
   - Heroku (easiest)
   - AWS (most flexible)
   - DigitalOcean (good value)

2. **Update iOS App**
   - Change API URL
   - Test on simulator (need Mac)

3. **Submit to App Store**
   - Need Mac for final build
   - Can test logic on Windows first

---

## 📚 Additional Resources

- **Backend README**: `backend/README.md`
- **Deployment Guide**: `DEPLOYMENT_GUIDE.md`
- **API Reference**: `backend/README.md#endpoints`
- **Troubleshooting**: `DEPLOYMENT_GUIDE.md#troubleshooting`

---

**Happy Testing!** 🚀

For iOS/Swift testing, you'll need Mac access. But you can thoroughly test the backend and verify all the API logic on Windows right now.
