defmodule FlamePingMonitor.Repo do
  use Ecto.Repo,
    otp_app: :flame_ping_monitor,
    adapter: Ecto.Adapters.SQLite3
end
