# FLAME Distributed Ping Monitor Plan

## Professional & Clean Design Theme
- Dark theme with green/red status indicators
- Modern card-based layout
- Clean typography and subtle animations
- Professional monitoring dashboard aesthetic

## Completed Steps
- [x] Generate Phoenix LiveView project called `flame_ping_monitor`
- [x] Add FLAME dependency for distributed monitoring
- [x] Start server for real-time development feedback

## Remaining Steps
- [ ] Replace home page with static design mockup
- [ ] Create Domain schema and migration for storing monitored domains
  - Domain fields: url (string), name (string), status (enum), last_ping_at (datetime), response_time (integer)
- [ ] Build DomainLive with real-time domain list and add/delete functionality
  - Real-time updates via PubSub
  - Add domain form with validation
  - Delete domain functionality
  - Status indicators (up/down/checking)
- [ ] Create PingResult schema for historical ping data
  - Fields: domain_id, status, response_time, pinged_at, error_message
- [ ] Implement PingMonitor context with FLAME-powered distributed ping workers
  - FLAME.call/2 for spawning distributed ping workers
  - Handle ping responses and broadcast via PubSub
  - Store results in PingResult schema
- [ ] Add periodic ping scheduling (every 30 seconds per domain)
- [ ] Style root.html.heex and layouts to match professional & clean design
- [ ] Update router to replace placeholder home route with DomainLive
- [ ] Visit app to verify complete FLAME distributed ping monitoring

## Key Features
- Global distributed ping monitoring via FLAME
- Real-time status updates across all connected browsers
- Historical ping data and response times
- Professional monitoring dashboard UI
- No authentication required - public monitoring tool

Total estimated steps: 14
