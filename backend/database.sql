-- MomentumOS Database Schema
-- PostgreSQL Setup Script
-- Create tables for all app features

-- MARK: - Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    avatar VARCHAR(500),
    provider VARCHAR(50), -- 'email', 'apple', 'google', 'facebook'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_sync TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- MARK: - Habits Table
CREATE TABLE habits (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    frequency VARCHAR(50), -- 'daily', 'weekly', 'custom'
    icon VARCHAR(100),
    color VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Habit Logs Table
CREATE TABLE habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    completed_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Mood Entries Table
CREATE TABLE moods (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    level VARCHAR(50) NOT NULL, -- 'terrible', 'sad', 'neutral', 'good', 'excellent'
    energy INTEGER, -- 1-10
    stress INTEGER, -- 1-10
    sleep DECIMAL, -- 0-12 hours
    triggers TEXT, -- JSON array
    notes TEXT,
    date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Workouts Table
CREATE TABLE workouts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'strength', 'cardio', 'flexibility', etc
    intensity VARCHAR(50), -- 'light', 'moderate', 'intense'
    duration INTEGER NOT NULL, -- minutes
    exercises TEXT, -- JSON array
    estimated_calories DECIMAL,
    date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Meals Table
CREATE TABLE meals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'breakfast', 'lunch', 'dinner', 'snack'
    foods TEXT NOT NULL, -- JSON array of food items
    date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Tasks Table
CREATE TABLE tasks (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    priority VARCHAR(50), -- 'low', 'medium', 'high'
    quadrant VARCHAR(50), -- 'urgent-important', 'not-urgent-important', etc
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Routines Table
CREATE TABLE routines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    time VARCHAR(50), -- 'morning', 'afternoon', 'evening'
    tasks TEXT NOT NULL, -- JSON array
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Goals Table
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    target_value DECIMAL,
    current_value DECIMAL DEFAULT 0,
    deadline TIMESTAMP,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Achievements Table
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    category VARCHAR(50),
    unlockedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Notifications Table
CREATE TABLE notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    enable_habit_reminders BOOLEAN DEFAULT true,
    enable_focus_reminders BOOLEAN DEFAULT true,
    enable_mood_reminders BOOLEAN DEFAULT false,
    enable_motivational_boosts BOOLEAN DEFAULT true,
    enable_streak_reminders BOOLEAN DEFAULT true,
    quiet_hours_enabled BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    sound_enabled BOOLEAN DEFAULT true,
    haptic_feedback BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Analytics Events Table
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_name VARCHAR(255) NOT NULL,
    properties JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_timestamp (user_id, timestamp),
    INDEX idx_event_name (event_name)
);

-- MARK: - Subscriptions Table
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    tier VARCHAR(50), -- 'free', 'pro', 'premium'
    status VARCHAR(50), -- 'active', 'cancelled', 'expired'
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    trial_start TIMESTAMP,
    trial_end TIMESTAMP,
    is_trial BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Social Profiles Table
CREATE TABLE social_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name VARCHAR(255),
    bio TEXT,
    avatar_url VARCHAR(500),
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Friends Table
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50), -- 'pending', 'accepted', 'blocked'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, friend_id)
);

-- MARK: - Sessions Table (for tracking focus sessions)
CREATE TABLE focus_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    category VARCHAR(50),
    duration INTEGER, -- minutes
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MARK: - Health Data Cache Table
CREATE TABLE health_data_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    data_type VARCHAR(100), -- 'steps', 'calories', 'heart_rate', etc
    value DECIMAL NOT NULL,
    date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, data_type, date)
);

-- MARK: - Indexes for Performance
CREATE INDEX idx_habits_user ON habits(user_id);
CREATE INDEX idx_habit_logs_habit ON habit_logs(habit_id);
CREATE INDEX idx_habit_logs_date ON habit_logs(completed_at);
CREATE INDEX idx_moods_user ON moods(user_id);
CREATE INDEX idx_moods_date ON moods(date);
CREATE INDEX idx_workouts_user ON workouts(user_id);
CREATE INDEX idx_workouts_date ON workouts(date);
CREATE INDEX idx_meals_user ON meals(user_id);
CREATE INDEX idx_meals_date ON meals(date);
CREATE INDEX idx_tasks_user ON tasks(user_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_routines_user ON routines(user_id);
CREATE INDEX idx_goals_user ON goals(user_id);
CREATE INDEX idx_achievements_user ON achievements(user_id);
CREATE INDEX idx_focus_sessions_user ON focus_sessions(user_id);
CREATE INDEX idx_health_data_user_date ON health_data_cache(user_id, date);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- MARK: - Views for Common Queries

-- Weekly habit completion view
CREATE VIEW habit_completion_weekly AS
SELECT 
    h.id,
    h.name,
    h.user_id,
    COUNT(CASE WHEN hl.completed_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as completions_this_week,
    COUNT(hl.id) as total_completions
FROM habits h
LEFT JOIN habit_logs hl ON h.id = hl.habit_id
GROUP BY h.id, h.name, h.user_id;

-- User activity view
CREATE VIEW user_activity AS
SELECT 
    u.id,
    u.name,
    u.email,
    COUNT(DISTINCT h.id) as total_habits,
    COUNT(DISTINCT w.id) as total_workouts,
    COUNT(DISTINCT m.id) as total_meals,
    COUNT(DISTINCT mo.id) as total_mood_logs,
    u.last_sync
FROM users u
LEFT JOIN habits h ON u.id = h.user_id
LEFT JOIN workouts w ON u.id = w.user_id
LEFT JOIN meals m ON u.id = m.user_id
LEFT JOIN moods mo ON u.id = mo.user_id
GROUP BY u.id, u.name, u.email, u.last_sync;

-- MARK: - Triggers for Automatic Timestamps
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_habits_timestamp
BEFORE UPDATE ON habits
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_workouts_timestamp
BEFORE UPDATE ON workouts
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_meals_timestamp
BEFORE UPDATE ON meals
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_tasks_timestamp
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- MARK: - Test Data (Optional - for development)
-- INSERT INTO users (id, email, password, name) VALUES
-- (gen_random_uuid(), 'test@momentumos.app', 'hashed_password', 'Test User');

-- MARK: - Grants (for application user)
-- CREATE USER momentumos_app WITH PASSWORD 'secure_password';
-- GRANT CONNECT ON DATABASE momentumos TO momentumos_app;
-- GRANT USAGE ON SCHEMA public TO momentumos_app;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO momentumos_app;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO momentumos_app;
