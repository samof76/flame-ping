defmodule FlamePingMonitor.Monitoring.PingMonitorTest do
  use FlamePingMonitor.DataCase

  alias FlamePingMonitor.Monitoring.{PingMonitor, Domain, PingResult}
  alias FlamePingMonitor.Repo
  import Ecto.Query

  describe "handle_ping_result/5" do
    setup do
      domain = insert_domain()
      %{domain: domain}
    end

    test "successful ping updates domain status", %{domain: domain} do
      {:ok, updated_domain} =
        PingMonitor.handle_ping_result(domain.id, "online", 150, nil, "na")

      assert updated_domain.status == "online"
      assert updated_domain.response_time == 150
      assert updated_domain.consecutive_failures == 0
      assert updated_domain.last_failure_at == nil
      refute is_nil(updated_domain.last_ping_at)
    end

    test "failed ping increments consecutive failures", %{domain: domain} do
      {:ok, updated_domain} =
        PingMonitor.handle_ping_result(domain.id, "offline", nil, "Connection timeout", "na")

      assert updated_domain.status == "offline"
      assert updated_domain.consecutive_failures == 1
      assert updated_domain.error_message == "Connection timeout"
      refute is_nil(updated_domain.last_failure_at)
    end

    test "successful ping after failure resets consecutive failures", %{domain: domain} do
      # First, create a domain with failures
      domain =
        domain
        |> Domain.changeset(%{consecutive_failures: 3, last_failure_at: DateTime.utc_now()})
        |> Repo.update!()

      {:ok, updated_domain} =
        PingMonitor.handle_ping_result(domain.id, "online", 120, nil, "eu")

      assert updated_domain.status == "online"
      assert updated_domain.consecutive_failures == 0
      assert updated_domain.last_failure_at == nil
    end

    test "creates ping result record", %{domain: domain} do
      PingMonitor.handle_ping_result(domain.id, "online", 180, nil, "as")

      ping_result =
        from(pr in PingResult,
          where: pr.domain_id == ^domain.id,
          order_by: [desc: pr.pinged_at],
          limit: 1
        )
        |> Repo.one()

      assert ping_result.status == "online"
      assert ping_result.response_time == 180
      assert ping_result.region == "as"
      assert ping_result.error_message == nil
    end

    test "creates ping result with error message", %{domain: domain} do
      PingMonitor.handle_ping_result(domain.id, "offline", nil, "HTTP 500", "sa")

      ping_result =
        from(pr in PingResult,
          where: pr.domain_id == ^domain.id,
          order_by: [desc: pr.pinged_at],
          limit: 1
        )
        |> Repo.one()

      assert ping_result.status == "offline"
      assert ping_result.response_time == nil
      assert ping_result.region == "sa"
      assert ping_result.error_message == "HTTP 500"
    end

    test "broadcasts region ping update via PubSub", %{domain: domain} do
      Phoenix.PubSub.subscribe(FlamePingMonitor.PubSub, "domain_updates")

      PingMonitor.handle_ping_result(domain.id, "online", 90, nil, "oc")

      assert_receive {:region_ping_update, domain_id, "oc", "online", 90}
      assert domain_id == domain.id
    end
  end

  describe "create_ping_result/1" do
    setup do
      domain = insert_domain()
      %{domain: domain}
    end

    test "creates ping result with valid attributes", %{domain: domain} do
      attrs = %{
        domain_id: domain.id,
        status: "online",
        response_time: 200,
        pinged_at: NaiveDateTime.utc_now(),
        region: "eu"
      }

      {:ok, ping_result} = PingMonitor.create_ping_result(attrs)

      assert ping_result.domain_id == domain.id
      assert ping_result.status == "online"
      assert ping_result.response_time == 200
      assert ping_result.region == "eu"
    end

    test "returns error with invalid attributes" do
      attrs = %{status: "invalid"}

      {:error, changeset} = PingMonitor.create_ping_result(attrs)
      refute changeset.valid?
    end
  end

  describe "get_recent_ping_results/2" do
    setup do
      domain = insert_domain()
      %{domain: domain}
    end

    test "returns recent ping results ordered by timestamp", %{domain: domain} do
      # Create ping results with different timestamps
      now = NaiveDateTime.utc_now()

      for {offset, region} <- [{-300, "na"}, {-200, "eu"}, {-100, "as"}] do
        timestamp = NaiveDateTime.add(now, offset, :second)

        %PingResult{}
        |> PingResult.changeset(%{
          domain_id: domain.id,
          status: "online",
          response_time: 100,
          pinged_at: timestamp,
          region: region
        })
        |> Repo.insert!()
      end

      results = PingMonitor.get_recent_ping_results(domain.id, 10)

      assert length(results) == 3
      # Most recent first
      assert Enum.at(results, 0).region == "as"
      assert Enum.at(results, 1).region == "eu"
      assert Enum.at(results, 2).region == "na"
    end

    test "limits results to specified number", %{domain: domain} do
      # Create 5 ping results
      for i <- 1..5 do
        %PingResult{}
        |> PingResult.changeset(%{
          domain_id: domain.id,
          status: "online",
          response_time: 100,
          pinged_at: NaiveDateTime.utc_now(),
          region: "na"
        })
        |> Repo.insert!()
      end

      results = PingMonitor.get_recent_ping_results(domain.id, 3)
      assert length(results) == 3
    end
  end

  describe "get_recent_ping_results_by_region/3" do
    setup do
      domain = insert_domain()
      %{domain: domain}
    end

    test "returns results filtered by region", %{domain: domain} do
      # Create ping results for different regions
      for region <- ["na", "eu", "na", "as", "na"] do
        %PingResult{}
        |> PingResult.changeset(%{
          domain_id: domain.id,
          status: "online",
          response_time: 100,
          pinged_at: NaiveDateTime.utc_now(),
          region: region
        })
        |> Repo.insert!()
      end

      na_results = PingMonitor.get_recent_ping_results_by_region(domain.id, "na", 10)
      eu_results = PingMonitor.get_recent_ping_results_by_region(domain.id, "eu", 10)

      assert length(na_results) == 3
      assert length(eu_results) == 1
      assert Enum.all?(na_results, &(&1.region == "na"))
      assert Enum.all?(eu_results, &(&1.region == "eu"))
    end
  end

  describe "calculate_hourly_availability/2" do
    setup do
      domain = insert_domain()
      %{domain: domain}
    end

    test "calculates availability percentage correctly", %{domain: domain} do
      now = NaiveDateTime.utc_now()

      # Create 8 online results and 2 offline results in the last hour
      for i <- 1..8 do
        timestamp = NaiveDateTime.add(now, -i * 60, :second)

        %PingResult{}
        |> PingResult.changeset(%{
          domain_id: domain.id,
          status: "online",
          response_time: 100,
          pinged_at: timestamp,
          region: "na"
        })
        |> Repo.insert!()
      end

      for i <- 9..10 do
        timestamp = NaiveDateTime.add(now, -i * 60, :second)

        %PingResult{}
        |> PingResult.changeset(%{
          domain_id: domain.id,
          status: "offline",
          response_time: nil,
          pinged_at: timestamp,
          region: "na"
        })
        |> Repo.insert!()
      end

      availability = PingMonitor.calculate_hourly_availability(domain.id, "na")
      # 8 online out of 10 total = 80%
      assert availability == 80.0
    end

    test "returns 0.0 for no results", %{domain: domain} do
      availability = PingMonitor.calculate_hourly_availability(domain.id, "na")
      assert availability == 0.0
    end

    test "ignores results older than one hour", %{domain: domain} do
      now = NaiveDateTime.utc_now()

      # Create an old result (2 hours ago)
      old_timestamp = NaiveDateTime.add(now, -7200, :second)

      %PingResult{}
      |> PingResult.changeset(%{
        domain_id: domain.id,
        status: "offline",
        response_time: nil,
        pinged_at: old_timestamp,
        region: "na"
      })
      |> Repo.insert!()

      # Create a recent result (30 minutes ago)
      recent_timestamp = NaiveDateTime.add(now, -1800, :second)

      %PingResult{}
      |> PingResult.changeset(%{
        domain_id: domain.id,
        status: "online",
        response_time: 100,
        pinged_at: recent_timestamp,
        region: "na"
      })
      |> Repo.insert!()

      availability = PingMonitor.calculate_hourly_availability(domain.id, "na")
      # Only the recent online result counts
      assert availability == 100.0
    end
  end

  describe "get_domain_region_status/1" do
    setup do
      domain = insert_domain()
      %{domain: domain}
    end

    test "returns status for all regions", %{domain: domain} do
      # Create ping results for some regions
      for region <- ["na", "eu"] do
        %PingResult{}
        |> PingResult.changeset(%{
          domain_id: domain.id,
          status: "online",
          response_time: 100,
          pinged_at: NaiveDateTime.utc_now(),
          region: region
        })
        |> Repo.insert!()
      end

      region_status = PingMonitor.get_domain_region_status(domain.id)

      # All 5 regions
      assert length(region_status) == 5
      assert Enum.any?(region_status, fn {region, _result, _availability} -> region == "na" end)
      assert Enum.any?(region_status, fn {region, _result, _availability} -> region == "eu" end)
      assert Enum.any?(region_status, fn {region, _result, _availability} -> region == "as" end)
      assert Enum.any?(region_status, fn {region, _result, _availability} -> region == "sa" end)
      assert Enum.any?(region_status, fn {region, _result, _availability} -> region == "oc" end)
    end
  end

  # Helper function to create test domain
  defp insert_domain do
    %Domain{}
    |> Domain.changeset(%{
      name: "Test Domain",
      url: "https://example.com"
    })
    |> Repo.insert!()
  end
end
