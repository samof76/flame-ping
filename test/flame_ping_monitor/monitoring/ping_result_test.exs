defmodule FlamePingMonitor.Monitoring.PingResultTest do
  use FlamePingMonitor.DataCase

  alias FlamePingMonitor.Monitoring.{PingResult, Domain}

  describe "changeset/2" do
    setup do
      domain = insert(:domain)
      %{domain: domain}
    end

    test "valid changeset with required fields", %{domain: domain} do
      attrs = %{
        domain_id: domain.id,
        status: "online",
        response_time: 150,
        pinged_at: NaiveDateTime.utc_now(),
        region: "na"
      }

      changeset = PingResult.changeset(%PingResult{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :domain_id) == domain.id
      assert get_field(changeset, :status) == "online"
      assert get_field(changeset, :response_time) == 150
      assert get_field(changeset, :region) == "na"
    end

    test "valid changeset with error message", %{domain: domain} do
      attrs = %{
        domain_id: domain.id,
        status: "offline",
        response_time: nil,
        pinged_at: NaiveDateTime.utc_now(),
        region: "eu",
        error_message: "Connection timeout"
      }

      changeset = PingResult.changeset(%PingResult{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :status) == "offline"
      assert get_field(changeset, :error_message) == "Connection timeout"
      assert get_field(changeset, :region) == "eu"
    end

    test "invalid changeset missing required fields" do
      changeset = PingResult.changeset(%PingResult{}, %{})

      refute changeset.valid?

      assert %{
               domain_id: ["can't be blank"],
               status: ["can't be blank"],
               pinged_at: ["can't be blank"],
               region: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "invalid changeset with invalid status", %{domain: domain} do
      attrs = %{
        domain_id: domain.id,
        status: "invalid_status",
        pinged_at: NaiveDateTime.utc_now(),
        region: "na"
      }

      changeset = PingResult.changeset(%PingResult{}, attrs)

      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "invalid changeset with invalid region", %{domain: domain} do
      attrs = %{
        domain_id: domain.id,
        status: "online",
        pinged_at: NaiveDateTime.utc_now(),
        region: "invalid_region"
      }

      changeset = PingResult.changeset(%PingResult{}, attrs)

      refute changeset.valid?
      assert %{region: ["is invalid"]} = errors_on(changeset)
    end

    test "valid changeset with all supported statuses", %{domain: domain} do
      statuses = ["online", "offline", "checking"]

      for status <- statuses do
        attrs = %{
          domain_id: domain.id,
          status: status,
          pinged_at: NaiveDateTime.utc_now(),
          region: "na"
        }

        changeset = PingResult.changeset(%PingResult{}, attrs)
        assert changeset.valid?, "Status #{status} should be valid"
      end
    end

    test "valid changeset with all supported regions", %{domain: domain} do
      regions = ["na", "eu", "as", "sa", "oc"]

      for region <- regions do
        attrs = %{
          domain_id: domain.id,
          status: "online",
          pinged_at: NaiveDateTime.utc_now(),
          region: region
        }

        changeset = PingResult.changeset(%PingResult{}, attrs)
        assert changeset.valid?, "Region #{region} should be valid"
      end
    end

    test "allows nil response_time for offline status", %{domain: domain} do
      attrs = %{
        domain_id: domain.id,
        status: "offline",
        response_time: nil,
        pinged_at: NaiveDateTime.utc_now(),
        region: "na"
      }

      changeset = PingResult.changeset(%PingResult{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :response_time) == nil
    end
  end

  # Helper function to create test domain
  defp insert(factory) do
    case factory do
      :domain ->
        %Domain{}
        |> Domain.changeset(%{
          name: "Test Domain",
          url: "https://example.com"
        })
        |> FlamePingMonitor.Repo.insert!()
    end
  end
end
