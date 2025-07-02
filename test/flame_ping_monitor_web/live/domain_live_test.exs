defmodule FlamePingMonitorWeb.DomainLiveTest do
  use FlamePingMonitorWeb.ConnCase
  import Phoenix.LiveViewTest

  alias FlamePingMonitor.Monitoring.Domain
  alias FlamePingMonitor.Repo

  describe "mount" do
    test "renders the dashboard with empty state", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      assert html =~ "FLAME Ping Monitor"
      assert html =~ "Multi-Region Distributed Monitoring"
      assert html =~ "No domains added yet"
      assert html =~ "Add your first domain to start multi-region monitoring"
    end

    test "renders domains when they exist", %{conn: conn} do
      domain = insert_domain(%{name: "Google", url: "https://google.com"})

      {:ok, view, html} = live(conn, "/")

      assert html =~ "Google"
      assert html =~ "https://google.com"
      assert html =~ "Total Domains"
      refute html =~ "No domains added yet"
    end

    test "displays regional status cards", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      assert html =~ "Total Domains"
      assert html =~ "Online Regions"
      assert html =~ "Offline Regions"
      assert html =~ "Active Regions"
    end
  end

  describe "add domain form" do
    test "shows form when new_domain event is triggered", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Initially form is hidden
      refute has_element?(view, "#domain-form")

      # Click add domain button
      view |> element("button", "Add Domain") |> render_click()

      # Form should now be visible
      assert has_element?(view, "#domain-form")
      assert has_element?(view, "input[name='domain[name]']")
      assert has_element?(view, "input[name='domain[url]']")
      assert has_element?(view, "input[name='domain[webhook_url]']")
    end

    test "hides form when cancel event is triggered", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Show the form first
      view |> element("button", "Add Domain") |> render_click()
      assert has_element?(view, "#domain-form")

      # Cancel the form
      view |> element("button", "Cancel") |> render_click()

      # Form should be hidden
      refute has_element?(view, "#domain-form")
    end

    test "validates form fields on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button", "Add Domain") |> render_click()

      # Submit empty form to trigger validation
      html =
        view
        |> form("#domain-form", domain: %{name: "", url: ""})
        |> render_change()

      # Should show validation errors
      assert html =~ "can&#39;t be blank"
    end

    test "creates domain with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button", "Add Domain") |> render_click()

      # Submit valid form
      view
      |> form("#domain-form",
        domain: %{
          name: "Test Site",
          url: "https://test.com",
          webhook_url: "https://hooks.slack.com/test"
        }
      )
      |> render_submit()

      # Should create domain and hide form
      refute has_element?(view, "#domain-form")
      assert has_element?(view, "[data-testid='domain-Test Site']") || render(view) =~ "Test Site"

      # Verify domain was created in database
      domain = Repo.get_by(Domain, name: "Test Site")
      assert domain.url == "https://test.com"
      assert domain.webhook_url == "https://hooks.slack.com/test"
    end

    test "auto-prepends http:// to url without protocol", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button", "Add Domain") |> render_click()

      view
      |> form("#domain-form",
        domain: %{
          name: "Test Site",
          url: "test.com"
        }
      )
      |> render_submit()

      # Verify URL was auto-corrected
      domain = Repo.get_by(Domain, name: "Test Site")
      assert domain.url == "http://test.com"
    end

    test "shows error for invalid webhook URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view |> element("button", "Add Domain") |> render_click()

      html =
        view
        |> form("#domain-form",
          domain: %{
            name: "Test Site",
            url: "https://test.com",
            webhook_url: "invalid-url"
          }
        )
        |> render_change()

      assert html =~ "must be a valid HTTP or HTTPS URL"
    end
  end

  describe "delete domain" do
    test "deletes domain when delete button is clicked", %{conn: conn} do
      domain = insert_domain(%{name: "Delete Me", url: "https://delete.com"})

      {:ok, view, _html} = live(conn, "/")

      # Domain should be visible initially
      assert render(view) =~ "Delete Me"

      # Click delete button
      view |> element("button[phx-click='delete'][phx-value-id='#{domain.id}']") |> render_click()

      # Domain should be removed from view
      refute render(view) =~ "Delete Me"

      # Verify domain was deleted from database
      refute Repo.get(Domain, domain.id)
    end
  end

  describe "real-time updates" do
    test "receives domain_added broadcast", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Create domain outside the LiveView (simulating another user)
      domain = insert_domain(%{name: "Broadcast Test", url: "https://broadcast.com"})

      # Send broadcast message
      Phoenix.PubSub.broadcast(
        FlamePingMonitor.PubSub,
        "domain_updates",
        {:domain_added, domain}
      )

      # Should update the view
      assert render(view) =~ "Broadcast Test"
    end

    test "receives region_ping_update broadcast", %{conn: conn} do
      domain = insert_domain(%{name: "Ping Test", url: "https://ping.com"})
      {:ok, view, _html} = live(conn, "/")

      # Send ping update broadcast
      Phoenix.PubSub.broadcast(
        FlamePingMonitor.PubSub,
        "domain_updates",
        {:region_ping_update, domain.id, "na", "online", 150}
      )

      # View should re-render with updated data
      html = render(view)
      assert html =~ "Ping Test"
    end
  end

  describe "webhook indicators" do
    test "shows webhook enabled indicator when webhook_url is present", %{conn: conn} do
      insert_domain(%{
        name: "Webhook Site",
        url: "https://webhook.com",
        webhook_url: "https://hooks.slack.com/test"
      })

      {:ok, view, html} = live(conn, "/")

      assert html =~ "Webhook enabled"
    end

    test "does not show webhook indicator when webhook_url is empty", %{conn: conn} do
      insert_domain(%{
        name: "No Webhook Site",
        url: "https://nowebhook.com",
        webhook_url: ""
      })

      {:ok, view, html} = live(conn, "/")

      refute html =~ "Webhook enabled"
    end
  end

  # Helper function to create test domain
  defp insert_domain(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Domain",
      url: "https://example.com"
    }

    %Domain{}
    |> Domain.changeset(Map.merge(default_attrs, attrs))
    |> Repo.insert!()
  end
end
