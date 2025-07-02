# 🚀 FLAME Ping Monitor - Deployment Guide

A complete guide to deploying the **FLAME Ping Monitor** to production on Fly.io with multi-region distributed monitoring capabilities.

## 📋 **Prerequisites**

### Required Tools
- **Fly CLI**: Install from [fly.io/docs/getting-started/installing-flyctl/](https://fly.io/docs/getting-started/installing-flyctl/)
- **Elixir 1.15+** with **Erlang/OTP 26+**
- **Git** for version control
- **Phoenix 1.8+** (included in project)

### Fly.io Account Setup
```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Login to your Fly.io account
fly auth login

# Verify installation
fly version
```

## 🏗️ **Project Setup**

### 1. Clone and Prepare
```bash
# Clone the repository
git clone https://github.com/your-org/flame_ping_monitor.git
cd flame_ping_monitor

# Install dependencies
mix setup

# Verify local functionality
mix phx.server
# Visit http://localhost:4000 to confirm working state
```

### 2. Environment Configuration
```bash
# Generate production secret
mix phx.gen.secret

# Note the output - you'll need this for Fly secrets
```

## 🛠️ **Fly.io Configuration**

### 1. Initialize Fly Application
```bash
# Launch interactive setup
fly launch

# Answer the prompts:
# - App name: flame-ping-monitor (or your preferred name)
# - Region: Choose primary region (e.g., iad - US East)
# - Database: No (we use SQLite)
# - Deploy now: No (we'll configure first)
```

This creates a `fly.toml` configuration file.

### 2. Configure fly.toml
Edit the generated `fly.toml` file:

```toml
app = "flame-ping-monitor"
primary_region = "iad"

[build]

[env]
  PHX_HOST = "flame-ping-monitor.fly.dev"
  PORT = "8080"
  FLAME_BACKEND = "fly"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1
  processes = ["app"]

[[http_service.checks]]
  interval = "10s"
  timeout = "2s"
  grace_period = "5s"
  method = "GET"
  path = "/health"
  protocol = "http"

[http_service.concurrency]
  type = "connections"
  hard_limit = 1000
  soft_limit = 500

[[vm]]
  memory = "1gb"
  cpu_kind = "shared"
  cpus = 1

[processes]
  app = "bin/flame_ping_monitor start"
```

### 3. Set Production Secrets
```bash
# Set the secret key (use output from mix phx.gen.secret)
fly secrets set SECRET_KEY_BASE="your-generated-secret-key"

# Set database URL for SQLite
fly secrets set DATABASE_URL="ecto://sqlite:///app/db/flame_ping_monitor.db"

# Verify secrets are set
fly secrets list
```

## 🌍 **FLAME Multi-Region Setup**

### 1. Configure FLAME for Fly.io
Create `config/runtime.exs` if it doesn't exist:

```elixir
import Config

if config_env() == :prod do
  # Database configuration
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      """

  config :flame_ping_monitor, FlamePingMonitor.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # Phoenix configuration
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "8080")

  config :flame_ping_monitor, FlamePingMonitorWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true

  # FLAME configuration for multi-region
  config :flame, :backend, FLAME.FlyBackend
  
  config :flame, FLAME.FlyBackend,
    token: System.fetch_env!("FLY_API_TOKEN")
end
```

### 2. Set Fly API Token
```bash
# Get your Fly API token
fly auth token

# Set as secret (replace with your actual token)
fly secrets set FLY_API_TOKEN="your-fly-api-token"
```

## 📦 **Database Setup**

### 1. Configure SQLite for Production
Ensure `config/prod.exs` includes:

```elixir
config :flame_ping_monitor, FlamePingMonitor.Repo,
  adapter: Ecto.Adapters.SQLite3,
  pool_size: 10
```

### 2. Add Health Check Endpoint
Create `lib/flame_ping_monitor_web/controllers/health_controller.ex`:

```elixir
defmodule FlamePingMonitorWeb.HealthController do
  use FlamePingMonitorWeb, :controller

  def index(conn, _params) do
    # Simple health check
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", timestamp: DateTime.utc_now()})
  end
end
```

Add to router in `lib/flame_ping_monitor_web/router.ex`:

```elixir
scope "/", FlamePingMonitorWeb do
  pipe_through :api
  
  get "/health", HealthController, :index
end
```

## 🚀 **Deployment Process**

### 1. Pre-deployment Checks
```bash
# Ensure all tests pass
mix test

# Verify compilation
mix compile

# Check for unused dependencies
mix deps.unlock --check-unused

# Verify assets compile
mix assets.deploy
```

### 2. Deploy to Production
```bash
# Deploy the application
fly deploy

# Monitor deployment logs
fly logs

# Check application status
fly status
```

### 3. Post-deployment Verification
```bash
# Check if app is running
fly status

# View recent logs
fly logs --lines 50

# Test health endpoint
curl https://your-app-name.fly.dev/health

# Visit the application
fly open
```

## 🔧 **Production Monitoring**

### 1. Log Monitoring
```bash
# Real-time logs
fly logs -f

# Filter by component
fly logs | grep "PingMonitor"

# Check for errors
fly logs | grep "ERROR"
```

### 2. Application Metrics
```bash
# CPU and memory usage
fly metrics

# Connection stats
fly status --verbose

# Machine information
fly machine list
```

### 3. Database Monitoring
```bash
# Connect to production console
fly ssh console

# Inside the container, connect to app
bin/flame_ping_monitor remote

# Check domain count
iex> FlamePingMonitor.Repo.aggregate(FlamePingMonitor.Monitoring.Domain, :count)

# Recent ping results
iex> FlamePingMonitor.Repo.all(
  from p in FlamePingMonitor.Monitoring.PingResult,
  where: p.inserted_at > ago(1, "hour"),
  order_by: [desc: p.inserted_at],
  limit: 10
)
```

## 🔄 **Updates and Maintenance**

### 1. Application Updates
```bash
# Deploy new version
git push origin main
fly deploy

# Rollback if needed
fly releases list
fly releases rollback [version]
```

### 2. Scaling
```bash
# Scale up for higher load
fly scale count 2

# Scale down to save resources  
fly scale count 1

# Adjust VM resources
fly scale vm shared-cpu-2x --memory 2gb
```

### 3. Backup Strategy
```bash
# SQLite database backup
fly ssh console
sqlite3 /app/db/flame_ping_monitor.db ".backup /tmp/backup.db"
fly sftp get /tmp/backup.db ./local-backup.db
```

## 🚨 **Troubleshooting**

### Common Issues

#### 1. Application Won't Start
```bash
# Check deployment logs
fly logs

# Common causes:
# - Missing SECRET_KEY_BASE
# - Database connection issues
# - Asset compilation errors
```

#### 2. FLAME Workers Not Starting
```bash
# Verify FLY_API_TOKEN is set
fly secrets list

# Check FLAME backend configuration
fly logs | grep "FLAME"
```

#### 3. Database Issues
```bash
# Check SQLite permissions
fly ssh console
ls -la /app/db/

# Recreate database if needed
fly ssh console
rm /app/db/flame_ping_monitor.db
bin/flame_ping_monitor eval "FlamePingMonitor.Release.migrate"
```

#### 4. Health Check Failures
```bash
# Test health endpoint manually
curl https://your-app.fly.dev/health

# Check HTTP service configuration in fly.toml
```

### Performance Optimization

#### 1. Database Optimization
- Monitor SQLite performance with production load
- Consider read replicas for high-traffic scenarios
- Implement database connection pooling

#### 2. FLAME Worker Optimization
- Monitor regional ping distribution
- Adjust timeout values based on network conditions
- Implement circuit breakers for failing endpoints

#### 3. Caching Strategy
- Implement result caching for dashboard queries
- Use ETS for in-memory caching of recent ping results
- Consider Redis for distributed caching if scaling

## 📊 **Production Checklist**

### Pre-deployment
- [ ] All tests passing
- [ ] Secrets configured (`SECRET_KEY_BASE`, `FLY_API_TOKEN`)
- [ ] `fly.toml` properly configured
- [ ] Health check endpoint implemented
- [ ] Database migrations ready

### Post-deployment
- [ ] Application accessible via HTTPS
- [ ] Health check returns 200
- [ ] Multi-region pings functioning
- [ ] Real-time updates working
- [ ] Logs show no errors
- [ ] Domain monitoring active

### Ongoing Maintenance
- [ ] Regular log monitoring
- [ ] Database backup strategy
- [ ] Performance monitoring
- [ ] Security updates
- [ ] Cost optimization

## 🎯 **Production Best Practices**

1. **Security**
   - Rotate secrets regularly
   - Monitor access logs
   - Keep dependencies updated

2. **Reliability**
   - Monitor application health
   - Set up alerting for downtime
   - Test disaster recovery procedures

3. **Performance**
   - Monitor response times
   - Optimize database queries
   - Scale based on actual usage

4. **Cost Management**
   - Monitor Fly.io usage
   - Optimize FLAME worker distribution
   - Scale down during low-usage periods

---

**🚀 Ready for Production!** Your FLAME Ping Monitor is now deployed and monitoring websites across 5 continents.
