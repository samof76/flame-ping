defmodule FlamePingMonitor.Monitoring.DomainTest do
  use FlamePingMonitor.DataCase

  alias FlamePingMonitor.Monitoring.Domain

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        name: "My Website",
        url: "https://example.com"
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :name) == "My Website"
      assert get_field(changeset, :url) == "https://example.com"
      assert get_field(changeset, :status) == "checking"
      assert get_field(changeset, :consecutive_failures) == 0
    end

    test "valid changeset with all fields" do
      attrs = %{
        name: "Production Site",
        url: "https://mysite.com",
        webhook_url: "https://hooks.slack.com/services/webhook",
        status: "online",
        response_time: 150,
        consecutive_failures: 2
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :webhook_url) == "https://hooks.slack.com/services/webhook"
      assert get_field(changeset, :status) == "online"
      assert get_field(changeset, :response_time) == 150
      assert get_field(changeset, :consecutive_failures) == 2
    end

    test "invalid changeset missing required fields" do
      changeset = Domain.changeset(%Domain{}, %{})

      refute changeset.valid?
      assert %{name: ["can't be blank"], url: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset missing name" do
      attrs = %{url: "https://example.com"}
      changeset = Domain.changeset(%Domain{}, attrs)

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset missing url" do
      attrs = %{name: "My Site"}
      changeset = Domain.changeset(%Domain{}, attrs)

      refute changeset.valid?
      assert %{url: ["can't be blank"]} = errors_on(changeset)
    end

    test "auto-prepends http:// to url when missing protocol" do
      attrs = %{
        name: "My Website",
        url: "example.com"
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :url) == "http://example.com"
    end

    test "preserves https:// protocol in url" do
      attrs = %{
        name: "Secure Site",
        url: "https://secure.example.com"
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :url) == "https://secure.example.com"
    end

    test "valid webhook url with https" do
      attrs = %{
        name: "My Website",
        url: "https://example.com",
        webhook_url: "https://hooks.slack.com/services/webhook"
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
    end

    test "valid webhook url with http" do
      attrs = %{
        name: "My Website",
        url: "https://example.com",
        webhook_url: "http://localhost:3000/webhook"
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
    end

    test "invalid webhook url without protocol" do
      attrs = %{
        name: "My Website",
        url: "https://example.com",
        webhook_url: "invalid-webhook-url"
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      refute changeset.valid?
      assert %{webhook_url: ["must be a valid HTTP or HTTPS URL"]} = errors_on(changeset)
    end

    test "allows empty webhook url" do
      attrs = %{
        name: "My Website",
        url: "https://example.com",
        webhook_url: ""
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
    end

    test "allows nil webhook url" do
      attrs = %{
        name: "My Website",
        url: "https://example.com",
        webhook_url: nil
      }

      changeset = Domain.changeset(%Domain{}, attrs)

      assert changeset.valid?
    end
  end
end
