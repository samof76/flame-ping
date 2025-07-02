defmodule FlamePingMonitorWeb.PageController do
  use FlamePingMonitorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
