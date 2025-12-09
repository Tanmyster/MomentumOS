# MomentumOS Backend API Server

A production-ready REST API backend for the MomentumOS iOS application, built with Node.js and Express.

## 📋 Features

- **User Authentication**: Email/password, Apple Sign-in, Google Sign-in integration
- **Data Management**: Habits, moods, workouts, meals, tasks, routines, goals
- **Sync Engine**: Bi-directional data synchronization with iOS clients
- **HealthKit Integration**: Receive and store health data from Apple HealthKit
- **AI Coach Ready**: Endpoints for AI-powered recommendations
- **Analytics**: Event tracking and user engagement metrics
- **Security**: JWT authentication, rate limiting, input validation
- **Database**: PostgreSQL with migrations and backups
- **Deployment**: Docker support, Heroku/AWS/DigitalOcean ready

## 🚀 Quick Start

### Prerequisites

- Node.js 16+ and npm
- PostgreSQL 12+
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/momentumos-api.git
   cd momentumos-api
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Set up database**
   ```bash
   createdb momentumos
   psql momentumos < database.sql
   ```

5. **Start the server**
   ```bash
   npm start
   ```

   Server will be available at `http://localhost:3000`

### Development

Run with hot reload:
```bash
npm run dev
```

## 📚 API Endpoints

### Authentication
- `POST /v1/auth/register` - Register new user
- `POST /v1/auth/login` - Login with email/password
- `POST /v1/auth/social-login` - Social provider login
- `POST /v1/auth/refresh` - Refresh authentication token
- `POST /v1/auth/logout` - Logout user

### User Management
- `GET /v1/users/me` - Get current user profile
- `PUT /v1/users/me` - Update user profile
- `POST /v1/users/me/avatar` - Upload profile image

### Habits
- `POST /v1/habits` - Create new habit
- `GET /v1/habits` - List user habits
- `PUT /v1/habits/:habitId` - Update habit
- `DELETE /v1/habits/:habitId` - Delete habit
- `POST /v1/habits/:habitId/log` - Log habit completion

### Moods
- `POST /v1/moods` - Log mood entry
- `GET /v1/moods` - Get mood history
- `GET /v1/moods/stats` - Get mood statistics

### Workouts
- `POST /v1/workouts` - Create workout
- `GET /v1/workouts` - List workouts
- `PUT /v1/workouts/:workoutId` - Update workout
- `DELETE /v1/workouts/:workoutId` - Delete workout
- `GET /v1/workouts/stats` - Get workout statistics

### Meals
- `POST /v1/meals` - Log meal
- `GET /v1/meals` - Get meals for date
- `GET /v1/nutrition/stats` - Get nutrition statistics

### Tasks
- `POST /v1/tasks` - Create task
- `GET /v1/tasks` - List tasks
- `PUT /v1/tasks/:taskId` - Update task
- `POST /v1/tasks/:taskId/complete` - Complete task

### Sync
- `POST /v1/sync` - Synchronize all data

### Health Check
- `GET /v1/health` - Server health status

## 🔐 Authentication

All endpoints (except `/auth/*`) require JWT authentication via the `Authorization` header:

```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" https://api.momentumos.app/v1/users/me
```

## 📦 Database Schema

Key tables:
- `users` - User accounts and profiles
- `habits` - Daily habits
- `habit_logs` - Habit completion history
- `moods` - Mood entries
- `workouts` - Exercise sessions
- `meals` - Meal logs
- `tasks` - Todo items
- `routines` - Daily routines
- `goals` - Long-term goals
- `achievements` - User achievements
- `subscriptions` - Premium subscriptions
- `analytics_events` - Tracked events

See `database.sql` for complete schema.

## 🌐 Deployment

### Heroku
```bash
heroku create momentumos-api
heroku addons:create heroku-postgresql:hobby-dev
heroku config:set JWT_SECRET="your-secret"
git push heroku main
```

### Docker
```bash
docker build -t momentumos-api .
docker run -p 3000:3000 momentumos-api
```

### AWS EC2
```bash
# SSH into instance
ssh -i key.pem ubuntu@instance-ip

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone and deploy
git clone https://github.com/yourrepo/momentumos-api.git
cd momentumos-api
npm install
npm start
```

### DigitalOcean App Platform
1. Connect GitHub repository
2. Auto-deploy from main branch
3. Set environment variables in app platform UI
4. Database: Use managed PostgreSQL

## 🧪 Testing

Run tests:
```bash
npm test
```

With coverage:
```bash
npm test -- --coverage
```

## 📊 Environment Variables

See `.env.example` for all available options:

Critical variables:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Token signing secret (min 32 chars)
- `PORT` - Server port (default 3000)
- `NODE_ENV` - Development or production

## 🔧 Configuration

### Rate Limiting
Configured in middleware - 100 requests per 15 minutes per IP

### CORS
Allowed origins configured via `CORS_ORIGIN` env var

### Logging
Logs to console in development, file in production

## 📈 Monitoring

### Health Check
```bash
curl https://api.momentumos.app/v1/health
```

### Database Status
```bash
psql $DATABASE_URL -c "SELECT version();"
```

### Server Logs
```bash
# Local
npm run dev

# Heroku
heroku logs --tail

# PM2
pm2 logs
```

## 🐛 Troubleshooting

### Cannot connect to database
```bash
# Verify connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL
```

### Port already in use
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use different port
PORT=3001 npm start
```

### JWT authentication failing
- Verify JWT_SECRET is set correctly
- Check token hasn't expired
- Ensure Bearer token format: `Authorization: Bearer token`

### CORS errors from iOS app
- Verify CORS_ORIGIN matches app domain
- Check API URL in iOS BackendAPIService.swift

## 📝 API Documentation

Detailed API documentation available at `/api/docs` (when Swagger is enabled)

Example requests:

**Register**
```bash
curl -X POST https://api.momentumos.app/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "secure_password",
    "name": "John Doe"
  }'
```

**Create Habit**
```bash
curl -X POST https://api.momentumos.app/v1/habits \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "uuid-here",
    "name": "Morning Run",
    "category": "fitness",
    "frequency": "daily"
  }'
```

## 🚀 Performance Optimization

- Database indexing on frequently queried fields
- Connection pooling (pg)
- Rate limiting to prevent abuse
- GZIP compression enabled
- Response caching headers

## 🔒 Security Features

- Password hashing with bcrypt
- JWT token authentication
- Input validation and sanitization
- SQL injection prevention (parameterized queries)
- Rate limiting
- CORS security
- Helmet.js security headers

## 📞 Support

For issues:
1. Check GitHub issues
2. Review error logs
3. Test API endpoints manually
4. Verify environment variables

## 📄 License

MIT License - see LICENSE file

## 👥 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

**Version**: 1.0.0  
**Last Updated**: December 2025  
**Status**: Production Ready
