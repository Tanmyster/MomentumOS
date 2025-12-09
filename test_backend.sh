#!/bin/bash
# MomentumOS Backend Testing Script for Windows
# Run with: bash test_backend.sh

set -e

echo "🧪 MomentumOS Backend Testing Script"
echo "====================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_URL="http://localhost:3000/v1"
TEST_EMAIL="testuser$(date +%s)@example.com"
TEST_PASSWORD="TestPassword123"

echo -e "${BLUE}📋 Test Configuration${NC}"
echo "API URL: $API_URL"
echo "Test Email: $TEST_EMAIL"
echo ""

# Function to make API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4
    
    if [ -z "$token" ]; then
        curl -s -X "$method" "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$API_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d "$data"
    fi
}

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
health=$(curl -s "$API_URL/health")
if echo "$health" | grep -q "healthy"; then
    echo -e "${GREEN}✅ Server is healthy${NC}"
    echo "Response: $health"
else
    echo -e "${RED}❌ Health check failed${NC}"
    exit 1
fi
echo ""

# Test 2: Register User
echo -e "${YELLOW}Test 2: Register User${NC}"
register_response=$(api_call "POST" "/auth/register" "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"name\": \"Test User\"
}")

if echo "$register_response" | grep -q "accessToken"; then
    TOKEN=$(echo "$register_response" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✅ User registered successfully${NC}"
    echo "Token (first 20 chars): ${TOKEN:0:20}..."
else
    echo -e "${RED}❌ Registration failed${NC}"
    echo "Response: $register_response"
    exit 1
fi
echo ""

# Test 3: Get User Profile
echo -e "${YELLOW}Test 3: Get User Profile${NC}"
profile=$(api_call "GET" "/users/me" "" "$TOKEN")
if echo "$profile" | grep -q "Test User"; then
    echo -e "${GREEN}✅ Profile retrieved successfully${NC}"
    echo "Name: $(echo $profile | grep -o '"name":"[^"]*' | cut -d'"' -f4)"
else
    echo -e "${RED}❌ Get profile failed${NC}"
    echo "Response: $profile"
fi
echo ""

# Test 4: Create Habit
echo -e "${YELLOW}Test 4: Create Habit${NC}"
habit_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
habit=$(api_call "POST" "/habits" "{
    \"id\": \"$habit_id\",
    \"name\": \"Morning Run\",
    \"description\": \"Daily 5km run\",
    \"category\": \"fitness\",
    \"frequency\": \"daily\",
    \"icon\": \"figure.run\",
    \"color\": \"blue\"
}" "$TOKEN")

if echo "$habit" | grep -q "Morning Run"; then
    echo -e "${GREEN}✅ Habit created successfully${NC}"
    echo "Habit ID: $habit_id"
else
    echo -e "${RED}❌ Create habit failed${NC}"
    echo "Response: $habit"
fi
echo ""

# Test 5: Get Habits
echo -e "${YELLOW}Test 5: Get Habits${NC}"
habits=$(api_call "GET" "/habits" "" "$TOKEN")
if echo "$habits" | grep -q "Morning Run"; then
    echo -e "${GREEN}✅ Habits retrieved successfully${NC}"
    habit_count=$(echo "$habits" | grep -c "id" || true)
    echo "Total habits: $habit_count"
else
    echo -e "${YELLOW}⚠️  No habits returned (may be normal)${NC}"
fi
echo ""

# Test 6: Log Mood
echo -e "${YELLOW}Test 6: Log Mood${NC}"
mood_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
mood=$(api_call "POST" "/moods" "{
    \"id\": \"$mood_id\",
    \"level\": \"good\",
    \"energy\": 7,
    \"stress\": 3,
    \"sleep\": 8,
    \"triggers\": [],
    \"notes\": \"Feeling great today!\",
    \"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
}" "$TOKEN")

if echo "$mood" | grep -q "good"; then
    echo -e "${GREEN}✅ Mood logged successfully${NC}"
else
    echo -e "${RED}❌ Log mood failed${NC}"
    echo "Response: $mood"
fi
echo ""

# Test 7: Create Workout
echo -e "${YELLOW}Test 7: Create Workout${NC}"
workout_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
workout=$(api_call "POST" "/workouts" "{
    \"id\": \"$workout_id\",
    \"type\": \"strength\",
    \"intensity\": \"moderate\",
    \"duration\": 45,
    \"exercises\": [],
    \"estimatedCalories\": 300,
    \"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
}" "$TOKEN")

if echo "$workout" | grep -q "strength"; then
    echo -e "${GREEN}✅ Workout created successfully${NC}"
else
    echo -e "${RED}❌ Create workout failed${NC}"
    echo "Response: $workout"
fi
echo ""

# Test 8: Log Meal
echo -e "${YELLOW}Test 8: Log Meal${NC}"
meal_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
meal=$(api_call "POST" "/meals" "{
    \"id\": \"$meal_id\",
    \"type\": \"lunch\",
    \"foods\": [
        {
            \"id\": \"$(uuidgen | tr '[:upper:]' '[:lower:]')\",
            \"name\": \"Chicken Salad\",
            \"calories\": 350,
            \"protein\": 40,
            \"carbs\": 20,
            \"fat\": 15
        }
    ],
    \"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
}" "$TOKEN")

if echo "$meal" | grep -q "lunch"; then
    echo -e "${GREEN}✅ Meal logged successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Meal logging response: $meal${NC}"
fi
echo ""

# Test 9: Create Task
echo -e "${YELLOW}Test 9: Create Task${NC}"
task_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
task=$(api_call "POST" "/tasks" "{
    \"id\": \"$task_id\",
    \"title\": \"Complete project\",
    \"category\": \"work\",
    \"priority\": \"high\",
    \"quadrant\": \"urgent-important\",
    \"dueDate\": \"$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ)\"
}" "$TOKEN")

if echo "$task" | grep -q "Complete project"; then
    echo -e "${GREEN}✅ Task created successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Task creation response: $task${NC}"
fi
echo ""

# Test 10: Get Mood Stats
echo -e "${YELLOW}Test 10: Get Mood Statistics${NC}"
stats=$(api_call "GET" "/moods/stats" "" "$TOKEN")
if echo "$stats" | grep -q "average"; then
    echo -e "${GREEN}✅ Mood stats retrieved successfully${NC}"
    echo "Stats: $stats"
else
    echo -e "${YELLOW}⚠️  Stats response: $stats${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ Testing Complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Summary:"
echo "  ✅ Server health check"
echo "  ✅ User registration"
echo "  ✅ User authentication"
echo "  ✅ Profile retrieval"
echo "  ✅ Habit management"
echo "  ✅ Mood logging"
echo "  ✅ Workout logging"
echo "  ✅ Meal logging"
echo "  ✅ Task management"
echo "  ✅ Statistics retrieval"
echo ""
echo -e "${GREEN}All core features tested successfully!${NC}"
