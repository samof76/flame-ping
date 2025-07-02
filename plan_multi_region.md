# Multi-Region FLAME Ping Monitor Enhancement Plan

## 🌍 **Core Features**
- **5-Region Distributed Pings**: North America, Europe, Asia, South America, Oceania
- **10-Second Ping Intervals**: Continuous monitoring per domain per region
- **Real-time Continent Columns**: Status dots (🟢🟡🔴) with latency display
- **1-Hour Availability Aggregation**: Rolling availability percentage per region
- **Enhanced Professional UI**: Continent-based dashboard with real-time updates

## 📋 **Implementation Steps**

### Database & Schema Changes
- [x] Create plan and start implementation
- [ ] Add `region` field to ping_results schema
- [ ] Create migration to add region field
- [ ] Update PingResult schema with region validation
- [ ] Create PingScheduler GenServer for 10-second intervals
- [ ] Update Domain schema with region-specific status tracking

### FLAME Multi-Region Architecture  
- [ ] Configure 5 regional FLAME pools (simulated with different worker configs)
- [ ] Update PingRunner to accept region parameter
- [ ] Enhance PingMonitor with region-aware ping coordination
- [ ] Implement availability calculation for 1-hour rolling windows

### Enhanced LiveView UI
- [ ] Update DomainLive with region-specific assigns
- [ ] Create continent status column layout
- [ ] Add real-time region status dots with latency
- [ ] Implement 1-hour availability percentage display
- [ ] Style professional multi-region dashboard

### Real-time Features
- [ ] Enhanced PubSub for region-specific broadcasts
- [ ] Real-time status dot updates per continent
- [ ] Live latency updates with color coding
- [ ] Automatic 10-second ping scheduling

### Testing & Verification
- [ ] Test multi-region ping functionality
- [ ] Verify real-time UI updates across regions
- [ ] Test availability calculations
- [ ] Verify 10-second ping intervals

## 🎯 **Target UI Layout**
