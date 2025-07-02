defmodule FlamePingMonitorWeb.DomainLive do
  use FlamePingMonitorWeb, :live_view
  alias FlamePingMonitor.Monitoring.{Domain, PingMonitor, PingScheduler}
  alias FlamePingMonitor.Repo
  import Ecto.Query

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(FlamePingMonitor.PubSub, "domain_updates")
    end

    domains = list_domains_with_region_status()

    {:ok,
     socket
     |> assign(:domains, domains)
     |> assign(:form, to_form(Domain.changeset(%Domain{}, %{})))
     |> assign(:show_form, false)
     |> assign(:regions, PingScheduler.regions())
     |> assign(:region_names, PingScheduler.region_names())
     |> assign(:region_flags, PingScheduler.region_flags())}
  end

  def handle_event("new_domain", _params, socket) do
    changeset = Domain.changeset(%Domain{}, %{})

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:show_form, true)}
  end

  def handle_event("validate", %{"domain" => domain_params}, socket) do
    changeset =
      %Domain{}
      |> Domain.changeset(domain_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"domain" => domain_params}, socket) do
    case create_domain(domain_params) do
      {:ok, domain} ->
        # Start FLAME ping monitoring for the new domain from all regions
        for region <- PingScheduler.regions() do
          Task.start(fn -> PingMonitor.start_region_ping(domain, region) end)
        end

        Phoenix.PubSub.broadcast(
          FlamePingMonitor.PubSub,
          "domain_updates",
          {:domain_added, domain}
        )

        {:noreply,
         socket
         |> put_flash(:info, "Domain added successfully!")
         |> assign(:show_form, false)
         |> assign(:form, to_form(Domain.changeset(%Domain{}, %{})))
         |> assign(:domains, list_domains_with_region_status())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    domain = Repo.get!(Domain, id)
    {:ok, _} = Repo.delete(domain)

    Phoenix.PubSub.broadcast(FlamePingMonitor.PubSub, "domain_updates", {:domain_deleted, domain})

    {:noreply,
     socket
     |> put_flash(:info, "Domain deleted successfully!")
     |> assign(:domains, list_domains_with_region_status())}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:form, to_form(Domain.changeset(%Domain{}, %{})))}
  end

  def handle_info({:domain_added, _domain}, socket) do
    {:noreply, assign(socket, :domains, list_domains_with_region_status())}
  end

  def handle_info({:domain_deleted, _domain}, socket) do
    {:noreply, assign(socket, :domains, list_domains_with_region_status())}
  end

  def handle_info({:region_ping_update, _domain_id, _region, _status, _response_time}, socket) do
    domains = list_domains_with_region_status()
    {:noreply, assign(socket, :domains, domains)}
  end

  def handle_info({:ping_update, _domain_id, _status, _response_time}, socket) do
    domains = list_domains_with_region_status()
    {:noreply, assign(socket, :domains, domains)}
  end

  defp list_domains do
    Repo.all(from d in Domain, order_by: [desc: d.inserted_at])
  end

  defp list_domains_with_region_status do
    domains = list_domains()

    Enum.map(domains, fn domain ->
      region_status = PingMonitor.get_domain_region_status(domain.id)
      Map.put(domain, :region_status, region_status)
    end)
  end

  defp create_domain(attrs) do
    %Domain{}
    |> Domain.changeset(attrs)
    |> Repo.insert()
  end
end
