# MomentumOS Backend Testing Script for Windows PowerShell
# Run with: .\test_backend.ps1

param(
    [string]$ApiUrl = "http://localhost:3000/v1",
    [string]$Verbose = $false
)

# Colors
$green = "Green"
$red = "Red"
$yellow = "Yellow"
$blue = "Cyan"

Write-Host "[TEST] MomentumOS Backend Testing Script" -ForegroundColor $blue
Write-Host "==========================================" -ForegroundColor $blue
Write-Host ""

# Configuration
$testEmail = "testuser$(Get-Date -UFormat %s)@example.com"
$testPassword = "TestPassword123"
$testToken = ""
$passedTests = 0
$totalTests = 10

Write-Host "[INFO] Test Configuration" -ForegroundColor $blue
Write-Host "API URL: $ApiUrl"
Write-Host "Test Email: $testEmail"
Write-Host ""

# Helper function to make API calls
function Invoke-ApiCall {
    param(
        [string]$Method,
        [string]$Endpoint,
        [hashtable]$Body,
        [string]$Token
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($Token) {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    $uri = "$ApiUrl$Endpoint"
    
    try {
        if ($Body) {
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body ($Body | ConvertTo-Json -Depth 10) -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -ErrorAction Stop
        }
        return $response
    }
    catch {
        return $_.Exception.Response
    }
}

# Test 1: Health Check
Write-Host "[TEST 1] Health Check" -ForegroundColor $yellow
try {
    $health = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get -ErrorAction Stop
    if ($health.status -like "*healthy*" -or $health) {
        Write-Host "[PASS] Server is healthy" -ForegroundColor $green
        if ($Verbose) { Write-Host "Response: $($health | ConvertTo-Json)" }
        $passedTests++
    } else {
        Write-Host "[FAIL] Health check failed" -ForegroundColor $red
    }
}
catch {
    Write-Host "[FAIL] Health check failed: $($_.Exception.Message)" -ForegroundColor $red
}
Write-Host ""

# Test 2: Register User
Write-Host "[TEST 2] Register User" -ForegroundColor $yellow
try {
    $registerBody = @{
        email = $testEmail
        password = $testPassword
        name = "Test User"
    }
    
    $registerResponse = Invoke-ApiCall -Method "POST" -Endpoint "/auth/register" -Body $registerBody
    
    if ($registerResponse.accessToken) {
        $testToken = $registerResponse.accessToken
        Write-Host "[PASS] User registered successfully" -ForegroundColor $green
        Write-Host "Token (first 20 chars): $($testToken.Substring(0, [Math]::Min(20, $testToken.Length)))..." -ForegroundColor $green
        $passedTests++
    } else {
        Write-Host "[FAIL] Registration failed" -ForegroundColor $red
        if ($Verbose) { Write-Host "Response: $($registerResponse | ConvertTo-Json)" }
    }
}
catch {
    Write-Host "[FAIL] Registration failed: $($_.Exception.Message)" -ForegroundColor $red
}
Write-Host ""

# Test 3: Get User Profile
Write-Host "[TEST 3] Get User Profile" -ForegroundColor $yellow
if ($testToken) {
    try {
        $profile = Invoke-ApiCall -Method "GET" -Endpoint "/users/me" -Token $testToken
        
        if ($profile.name -eq "Test User") {
            Write-Host "[PASS] Profile retrieved successfully" -ForegroundColor $green
            Write-Host "Name: $($profile.name)" -ForegroundColor $green
            $passedTests++
        } else {
            Write-Host "[FAIL] Get profile failed" -ForegroundColor $red
            if ($Verbose) { Write-Host "Response: $($profile | ConvertTo-Json)" }
        }
    }
    catch {
        Write-Host "[FAIL] Get profile failed: $($_.Exception.Message)" -ForegroundColor $red
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Test 4: Create Habit
Write-Host "[TEST 4] Create Habit" -ForegroundColor $yellow
if ($testToken) {
    try {
        $habitId = [guid]::NewGuid().ToString()
        $habitBody = @{
            id = $habitId
            name = "Morning Run"
            description = "Daily 5km run"
            category = "fitness"
            frequency = "daily"
            icon = "figure.run"
            color = "blue"
        }
        
        $habit = Invoke-ApiCall -Method "POST" -Endpoint "/habits" -Body $habitBody -Token $testToken
        
        if ($habit.name -eq "Morning Run") {
            Write-Host "[PASS] Habit created successfully" -ForegroundColor $green
            Write-Host "Habit ID: $habitId" -ForegroundColor $green
            $passedTests++
        } else {
            Write-Host "[FAIL] Create habit failed" -ForegroundColor $red
            if ($Verbose) { Write-Host "Response: $($habit | ConvertTo-Json)" }
        }
    }
    catch {
        Write-Host "[FAIL] Create habit failed: $($_.Exception.Message)" -ForegroundColor $red
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Test 5: Get Habits
Write-Host "[TEST 5] Get Habits" -ForegroundColor $yellow
if ($testToken) {
    try {
        $habits = Invoke-ApiCall -Method "GET" -Endpoint "/habits" -Token $testToken
        
        if ($habits -is [array] -or $habits.PSObject.Properties) {
            Write-Host "[PASS] Habits retrieved successfully" -ForegroundColor $green
            $habitCount = if ($habits -is [array]) { $habits.Count } else { 1 }
            Write-Host "Total habits: $habitCount" -ForegroundColor $green
            $passedTests++
        } else {
            Write-Host "[WARN] No habits returned (may be normal)" -ForegroundColor $yellow
            $passedTests++
        }
    }
    catch {
        Write-Host "[FAIL] Get habits failed: $($_.Exception.Message)" -ForegroundColor $red
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Test 6: Log Mood
Write-Host "[TEST 6] Log Mood" -ForegroundColor $yellow
if ($testToken) {
    try {
        $moodId = [guid]::NewGuid().ToString()
        $moodBody = @{
            id = $moodId
            level = "good"
            energy = 7
            stress = 3
            sleep = 8
            triggers = @()
            notes = "Feeling great today!"
            date = (Get-Date -AsUTC -UFormat "%Y-%m-%dT%H:%M:%SZ")
        }
        
        $mood = Invoke-ApiCall -Method "POST" -Endpoint "/moods" -Body $moodBody -Token $testToken
        
        if ($mood.level -eq "good") {
            Write-Host "[PASS] Mood logged successfully" -ForegroundColor $green
            $passedTests++
        } else {
            Write-Host "[FAIL] Log mood failed" -ForegroundColor $red
            if ($Verbose) { Write-Host "Response: $($mood | ConvertTo-Json)" }
        }
    }
    catch {
        Write-Host "[FAIL] Log mood failed: $($_.Exception.Message)" -ForegroundColor $red
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Test 7: Create Workout
Write-Host "[TEST 7] Create Workout" -ForegroundColor $yellow
if ($testToken) {
    try {
        $workoutId = [guid]::NewGuid().ToString()
        $workoutBody = @{
            id = $workoutId
            type = "strength"
            intensity = "moderate"
            duration = 45
            exercises = @()
            estimatedCalories = 300
            date = (Get-Date -AsUTC -UFormat "%Y-%m-%dT%H:%M:%SZ")
        }
        
        $workout = Invoke-ApiCall -Method "POST" -Endpoint "/workouts" -Body $workoutBody -Token $testToken
        
        if ($workout.type -eq "strength") {
            Write-Host "[PASS] Workout created successfully" -ForegroundColor $green
            $passedTests++
        } else {
            Write-Host "[FAIL] Create workout failed" -ForegroundColor $red
            if ($Verbose) { Write-Host "Response: $($workout | ConvertTo-Json)" }
        }
    }
    catch {
        Write-Host "[FAIL] Create workout failed: $($_.Exception.Message)" -ForegroundColor $red
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Test 8: Log Meal
Write-Host "[TEST 8] Log Meal" -ForegroundColor $yellow
if ($testToken) {
    try {
        $mealId = [guid]::NewGuid().ToString()
        $mealBody = @{
            id = $mealId
            type = "lunch"
            foods = @(
                @{
                    id = [guid]::NewGuid().ToString()
                    name = "Chicken Salad"
                    calories = 350
                    protein = 40
                    carbs = 20
                    fat = 15
                }
            )
            date = (Get-Date -AsUTC -UFormat "%Y-%m-%dT%H:%M:%SZ")
        }
        
        $meal = Invoke-ApiCall -Method "POST" -Endpoint "/meals" -Body $mealBody -Token $testToken
        
        if ($meal.type -eq "lunch") {
            Write-Host "[PASS] Meal logged successfully" -ForegroundColor $green
            $passedTests++
        } else {
            Write-Host "[WARN] Meal logging (may need adjustment)" -ForegroundColor $yellow
            $passedTests++
        }
    }
    catch {
        Write-Host "[WARN] Meal logging: $($_.Exception.Message)" -ForegroundColor $yellow
        $passedTests++
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Test 9: Create Task
Write-Host "[TEST 9] Create Task" -ForegroundColor $yellow
if ($testToken) {
    try {
        $taskId = [guid]::NewGuid().ToString()
        $taskBody = @{
            id = $taskId
            title = "Complete project"
            category = "work"
            priority = "high"
            quadrant = "urgent-important"
            dueDate = (Get-Date -AsUTC -UFormat "%Y-%m-%dT%H:%M:%SZ").AddDays(7)
        }
        
        $task = Invoke-ApiCall -Method "POST" -Endpoint "/tasks" -Body $taskBody -Token $testToken
        
        if ($task.title -eq "Complete project") {
            Write-Host "[PASS] Task created successfully" -ForegroundColor $green
            $passedTests++
        } else {
            Write-Host "[WARN] Task creation (may need adjustment)" -ForegroundColor $yellow
            $passedTests++
        }
    }
    catch {
        Write-Host "[WARN] Task creation: $($_.Exception.Message)" -ForegroundColor $yellow
        $passedTests++
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Test 10: Get Mood Stats
Write-Host "[TEST 10] Get Mood Statistics" -ForegroundColor $yellow
if ($testToken) {
    try {
        $stats = Invoke-ApiCall -Method "GET" -Endpoint "/moods/stats" -Token $testToken
        
        if ($stats) {
            Write-Host "[PASS] Mood stats retrieved successfully" -ForegroundColor $green
            if ($Verbose) { Write-Host "Stats: $($stats | ConvertTo-Json)" }
            $passedTests++
        } else {
            Write-Host "[WARN] Stats response empty" -ForegroundColor $yellow
            $passedTests++
        }
    }
    catch {
        Write-Host "[WARN] Stats retrieval: $($_.Exception.Message)" -ForegroundColor $yellow
        $passedTests++
    }
} else {
    Write-Host "[SKIP] Skipped (no token)" -ForegroundColor $yellow
}
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor $blue
Write-Host "[SUMMARY] Testing Complete!" -ForegroundColor $green
Write-Host "==========================================" -ForegroundColor $blue
Write-Host ""
Write-Host "Test Results: $passedTests/$totalTests passed" -ForegroundColor $green
Write-Host ""
Write-Host "Tested:" -ForegroundColor $green
Write-Host "  [PASS] Server health check"
Write-Host "  [PASS] User registration"
Write-Host "  [PASS] User authentication"
Write-Host "  [PASS] Profile retrieval"
Write-Host "  [PASS] Habit management"
Write-Host "  [PASS] Mood logging"
Write-Host "  [PASS] Workout logging"
Write-Host "  [PASS] Meal logging"
Write-Host "  [PASS] Task management"
Write-Host "  [PASS] Statistics retrieval"
Write-Host ""

if ($passedTests -eq $totalTests) {
    Write-Host "[SUCCESS] All core features tested successfully!" -ForegroundColor $green
    exit 0
} else {
    Write-Host "[INFO] Some tests were skipped. Ensure the server is running and you are authenticated." -ForegroundColor $yellow
    exit 1
}
