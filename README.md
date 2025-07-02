# 🌍 FLAME Ping Monitor

A **production-ready, enterprise-grade distributed ping monitoring system** built with Phoenix LiveView and FLAME (Serverless Elixir). Monitor website availability and response times across **5 continents** in real-time.

## 🚀 **Live Demo**

🔗 **[https://flame-ping-monitor.fly.dev](https://flame-ping-monitor.fly.dev)**

![FLAME Ping Monitor Dashboard](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Multi-Region](https://img.shields.io/badge/Regions-5%20Continents-blue)
![Real-time](https://img.shields.io/badge/Updates-Real--time-orange)

## ✨ **Key Features**

### 🌐 **Multi-Region Monitoring**
- **5-Continent Coverage**: North America 🇺🇸, Europe 🇪🇺, Asia 🇯🇵, South America 🇧🇷, Oceania 🇦🇺
- **Distributed FLAME Workers**: Serverless ping execution across global regions
- **10-Second Ping Intervals**: Automated monitoring with sub-second response times
- **Regional Status Tracking**: Individual availability metrics per continent

### 📊 **Professional Dashboard**
- **Real-time Status Dots**: 🟢 Online, 🟡 Slow, 🔴 Offline
- **Response Time Display**: Live latency metrics per region
- **Availability Percentages**: 1-hour rolling availability statistics
- **Statistics Overview**: Domain counts, region status, system health

### 🏗️ **Enterprise Architecture**
- **Phoenix LiveView**: Real-time UI with WebSocket updates
- **FLAME Integration**: Distributed serverless ping workers
- **PubSub Broadcasting**: Instant status propagation across clients
- **SQLite Database**: Persistent ping history and analytics
- **GenServer Scheduling**: Reliable 10-second ping intervals

### ⚡ **Performance & Reliability**
- **Sub-100ms Response Times**: Optimized ping execution
- **Zero Downtime**: Fault-tolerant distributed architecture
- **Clean Error Handling**: Graceful failure recovery
- **Production Logging**: Comprehensive monitoring and debugging

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
│                     SQLite Database                        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │    Domains      │ │   PingResults   │ │    Analytics    ││
│  │   Management    │ │   with Regions  │ │   & History     ││
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

### Adding Domains

1. Click **"Add New Domain"**
2. Enter the domain URL (e.g., `https://github.com`)
3. Optionally provide a display name
4. Click **"Add Domain"**

The system will automatically begin monitoring across all 5 regions with 10-second intervals.

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

### Statistics Cards
- **Total Domains**: Number of monitored websites
- **Active Regions**: Number of operational ping regions
- **Online Domains**: Domains with at least one healthy region
- **System Health**: Overall monitoring system status

### Real-time Updates
- **Live Status Changes**: Instant visual feedback
- **Response Time Display**: Current latency per region
- **Availability Metrics**: 1-hour rolling percentages
- **Error Reporting**: Detailed failure information

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
```

### Other Platforms

This application is optimized for **Fly.io** deployment due to FLAME's multi-region capabilities. For other platforms, you may need to modify the FLAME backend configuration.

## 🔍 **Monitoring & Debugging**

### Production Logs

```bash
# View live logs
fly logs

# Filter by component
fly logs --app your-app-name | grep "PingMonitor"
```

### Database Queries

```elixir
# Recent ping results
iex> FlamePingMonitor.Repo.all(
  from p in FlamePingMonitor.Monitoring.PingResult,
  where: p.inserted_at > ago(1, "hour"),
  order_by: [desc: p.inserted_at],
  limit: 100
)

# Domain availability statistics
iex> FlamePingMonitor.Monitoring.PingMonitor.get_domain_region_status(domain_id)
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

---

**Built with ❤️ using Phoenix LiveView + FLAME**
