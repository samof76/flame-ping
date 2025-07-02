# 🌍 FLAME Ping Monitor

A **production-ready, enterprise-grade distributed ping monitoring system** built with Phoenix LiveView and FLAME (Serverless Elixir). Monitor website availability and response times across **5 continents** in real-time with **automated webhook notifications** for critical failures.

## 🚀 **Live Demo**

🔗 **[https://flame-ping-monitor.fly.dev](https://flame-ping-monitor.fly.dev)**

![FLAME Ping Monitor Dashboard](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Multi-Region](https://img.shields.io/badge/Regions-5%20Continents-blue)
![Real-time](https://img.shields.io/badge/Updates-Real--time-orange)
![Webhooks](https://img.shields.io/badge/Webhooks-Enabled-purple)

## ✨ **Enterprise Features**

### 🌐 **Multi-Region Monitoring**
- **5-Continent Coverage**: North America 🇺🇸, Europe 🇪🇺, Asia 🇯🇵, South America 🇧🇷, Oceania 🇦🇺
- **Distributed FLAME Workers**: Serverless ping execution across global regions
- **10-Second Ping Intervals**: Automated monitoring with sub-second response times
- **Regional Status Tracking**: Individual availability metrics per continent

### 🔔 **Webhook Notification System**
- **Automated Failure Alerts**: JSON notifications on 6 consecutive ping failures
- **Customizable Endpoints**: Configure webhook URLs per domain
- **Rich Payload Data**: Includes failure count, timestamps, error details
- **Delivery Tracking**: Monitor webhook notification history
- **Enterprise Integration**: Works with Slack, Discord, PagerDuty, custom endpoints

### 📊 **Professional Dashboard**
- **Real-time Status Dots**: 🟢 Online, 🟡 Slow, 🔴 Offline
- **Response Time Display**: Live latency metrics per region
- **Availability Percentages**: 1-hour rolling availability statistics
- **Statistics Overview**: Domain counts, region status, system health
- **Webhook Status Indicators**: Visual confirmation of notification setup

### 🏗️ **Enterprise Architecture**
- **Phoenix LiveView**: Real-time UI with WebSocket updates
- **FLAME Integration**: Distributed serverless ping workers
- **PubSub Broadcasting**: Instant status propagation across clients
- **SQLite Database**: Persistent ping history and analytics
- **GenServer Scheduling**: Reliable 10-second ping intervals
- **Bot Protection Bypass**: Smart user-agent headers for accurate monitoring

### ⚡ **Performance & Reliability**
- **Sub-100ms Response Times**: Optimized ping execution
- **Zero Downtime**: Fault-tolerant distributed architecture
- **Clean Error Handling**: Graceful failure recovery
- **Production Logging**: Comprehensive monitoring and debugging
- **Failure Tracking**: Consecutive failure counting with automatic reset

## 🏗️ **System Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    Phoenix LiveView Frontend                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Dashboard     │ │  Real-time UI   │ │   Statistics    ││
│  │   Controls      │ │    Updates      │ │    Overview     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Phoenix PubSub                         │
│              Real-time Message Broadcasting                 │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                   PingScheduler GenServer                   │
│            10-Second Interval Management                    │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                 FLAME Distributed Workers                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────┐  │
│  │    NA    │ │    EU    │ │    AS    │ │    SA    │ │ OC │  │
│  │ 🇺🇸 Worker│ │ 🇪🇺 Worker│ │ 🇯🇵 Worker│ │ 🇧🇷 Worker│ │🇦🇺 W││
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └────┘  │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│              Webhook Notification Engine                    │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Failure Tracker │ │ JSON Payloads   │ │ HTTP Delivery   ││
│  │ (6 Consecutive) │ │ & Timestamps    │ │ to Endpoints    ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     SQLite Database                        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │    Domains      │ │   PingResults   │ │  Webhook Data   ││
│  │   & Webhooks    │ │   with Regions  │ │   & History     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### Prerequisites
- **Elixir 1.15+**
- **Erlang/OTP 26+**
- **Phoenix 1.8+**
- **SQLite**

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/flame_ping_monitor.git
cd flame_ping_monitor

# Install dependencies
mix setup

# Start the server
mix phx.server
```

Visit **[http://localhost:4000](http://localhost:4000)** to access the dashboard.

### Adding Domains with Webhook Notifications

1. Click **"Add New Domain"**
2. Enter the domain URL (e.g., `https://github.com`)
3. Optionally provide a display name
4. **Configure webhook URL** for failure notifications (optional)
   - Example: `https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK`
   - Supports any HTTP endpoint that accepts JSON POST requests
5. Click **"Add Domain"**

The system will automatically begin monitoring across all 5 regions with 10-second intervals. If 6 consecutive ping failures occur, a JSON notification will be sent to your webhook endpoint.

## 📦 **Tech Stack**

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Backend** | Phoenix 1.8 | Web framework and real-time features |
| **Frontend** | LiveView | Real-time UI with WebSocket updates |
| **Workers** | FLAME | Distributed serverless ping execution |
| **Database** | SQLite + Ecto | Data persistence and analytics |
| **Styling** | Tailwind CSS + DaisyUI | Professional responsive design |
| **Scheduling** | GenServer | Reliable ping interval management |
| **Broadcasting** | Phoenix PubSub | Real-time status propagation |
| **HTTP Client** | Req | High-performance HTTP requests |
| **Notifications** | Webhook System | JSON failure alerts |

## 🌍 **Regional Coverage**

| Region | Flag | Identifier | Coverage |
|--------|------|------------|----------|
| **North America** | 🇺🇸 | `na` | US East Coast |
| **Europe** | 🇪🇺 | `eu` | Western Europe |
| **Asia** | 🇯🇵 | `as` | East Asia |
| **South America** | 🇧🇷 | `sa` | Brazil |
| **Oceania** | 🇦🇺 | `oc` | Australia |

## 📈 **Dashboard Features**

### Status Indicators
- **🟢 Online**: Response time < 1000ms
- **🟡 Slow**: Response time 1000-5000ms  
- **🔴 Offline**: Timeout or HTTP error
- **🔔 Webhook Enabled**: Visual indicator for notification setup

### Statistics Cards
- **Total Domains**: Number of monitored websites
- **Online Regions**: Active monitoring regions across continents
- **Offline Regions**: Regions experiencing connectivity issues
- **Active Regions**: Total operational ping regions

### Real-time Updates
- **Live Status Changes**: Instant visual feedback
- **Response Time Display**: Current latency per region
- **Availability Metrics**: 1-hour rolling percentages
- **Error Reporting**: Detailed failure information

## 🔔 **Webhook Notification System**

### JSON Payload Format
When 6 consecutive ping failures occur, the system sends this JSON payload:

```json
{
  "domain": "https://example.com",
  "name": "My Website",
  "status": "critical_failure",
  "consecutive_failures": 6,
  "last_failure_at": "2024-01-15T10:30:00Z",
  "error_message": "Connection timeout",
  "timestamp": "2024-01-15T10:30:15Z"
}
```

### Supported Integrations
- **Slack Webhooks**: `https://hooks.slack.com/services/...`
- **Discord Webhooks**: `https://discord.com/api/webhooks/...`
- **Microsoft Teams**: `https://outlook.office.com/webhook/...`
- **PagerDuty Events API**: `https://events.pagerduty.com/v2/enqueue`
- **Custom Endpoints**: Any HTTP endpoint accepting JSON POST

### Webhook Configuration
1. Configure your webhook endpoint to accept HTTP POST requests
2. Parse the JSON payload for failure details
3. Implement your notification logic (Slack message, email, SMS, etc.)
4. Return HTTP 200 status for successful delivery confirmation

## 🔧 **Configuration**

### Environment Variables

```bash
# Database
DATABASE_URL="ecto://localhost/flame_ping_monitor_dev"

# Phoenix
SECRET_KEY_BASE="your-secret-key"
PHX_HOST="localhost"
PHX_PORT="4000"

# FLAME (Production)
FLAME_BACKEND="fly"
FLY_API_TOKEN="your-fly-token"
```

### Ping Configuration

```elixir
# lib/flame_ping_monitor/monitoring/ping_scheduler.ex
@ping_interval 10_000  # 10 seconds
@timeout 30_000       # 30 second timeout
@failure_threshold 6  # Webhook trigger threshold
```

## 🚀 **Deployment**

### Fly.io (Recommended)

```bash
# Initialize Fly app
fly launch

# Deploy
fly deploy

# Set production secrets
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set FLY_API_TOKEN="your-fly-api-token"
```

**Note**: This application is optimized for **Fly.io** deployment due to FLAME's multi-region capabilities. For other platforms, you may need to modify the FLAME backend configuration.

## 🔍 **Monitoring & Debugging**

### Production Logs

```bash
# View live logs
fly logs

# Filter by component
fly logs --app your-app-name | grep "PingMonitor"

# Monitor webhook deliveries
fly logs --app your-app-name | grep "Webhook"
```

### Database Queries

```elixir
# Recent ping results with region data
iex> FlamePingMonitor.Repo.all(
  from p in FlamePingMonitor.Monitoring.PingResult,
  where: p.inserted_at > ago(1, "hour"),
  order_by: [desc: p.inserted_at],
  limit: 100
)

# Domain availability statistics by region
iex> FlamePingMonitor.Monitoring.PingMonitor.get_domain_region_status(domain_id)

# Domains with webhook notifications enabled
iex> from(d in FlamePingMonitor.Monitoring.Domain, 
          where: not is_nil(d.webhook_url) and d.webhook_url != "") 
     |> FlamePingMonitor.Repo.all()
```

## 🤝 **Contributing**

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit changes** (`git commit -m 'Add amazing feature'`)
4. **Push to branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

## 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🏆 **Production Status**

✅ **Live Production Deployment**: [https://flame-ping-monitor.fly.dev](https://flame-ping-monitor.fly.dev)

✅ **Multi-Region Architecture**: 5-continent distributed monitoring

✅ **Enterprise-Grade Reliability**: Zero-downtime fault-tolerant design

✅ **Real-time Performance**: Sub-100ms response times with 10-second intervals

✅ **Webhook Notification System**: Automated JSON alerts for critical failures

✅ **Bot Protection Bypass**: Smart user-agent headers for accurate monitoring

---

**Built with ❤️ using Phoenix LiveView + FLAME**

*Monitor the world, get notified instantly.*
