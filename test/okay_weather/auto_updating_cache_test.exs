defmodule OkayWeather.AutoUpdatingCacheTest do
  use ExUnit.Case, async: true
  alias OkayWeather.AutoUpdatingCache

  setup do
    bypass = Bypass.open()
    %{bypass: bypass, bypass_domain: "http://localhost:#{bypass.port}"}
  end

  test "works with simple URLs", %{bypass: bypass, bypass_domain: bypass_domain} do
    body = "Hello, world"

    OkayWeather.Env.put_env(:fetch_before_startup?, true)

    Bypass.expect_once(bypass, "GET", "/", fn conn ->
      Plug.Conn.resp(conn, 200, body)
    end)

    {:ok, server} =
      AutoUpdatingCache.start_link(
        :url_test,
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> bypass_domain end,
          transform: fn body -> {:ok, String.upcase(body)} end
        }
      )

    assert AutoUpdatingCache.get(server) == {:ok, String.upcase(body)}
  end

  test "copes with HTTP error by falling back to fixed METAR", %{
    bypass: bypass,
    bypass_domain: bypass_domain
  } do
    OkayWeather.Env.put_env(:fetch_before_startup?, true)

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 500, "Internal Server Error")
    end)

    {:ok, server} =
      AutoUpdatingCache.start_link(
        String.to_atom("http_error_on_startup_#{Enum.random(1..1_000_000)}"),
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> bypass_domain end,
          transform: fn body -> {:ok, String.upcase(body)} end
        }
      )

    assert {:ok, metar} = AutoUpdatingCache.get(server)
    assert metar =~ "KLAX "
  end

  test "can skip fetching on startup and fall back to fixed METAR", %{bypass_domain: domain} do
    OkayWeather.Env.put_env(:fetch_before_startup?, false)

    {:ok, server} =
      AutoUpdatingCache.start_link(
        String.to_atom("failed_startup_#{Enum.random(1..1_000_000)}"),
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> domain end,
          transform: fn body -> {:ok, String.upcase(body)} end,
          update_timeout: :infinity
        }
      )

    assert {:ok, metar} = AutoUpdatingCache.get(server)
    assert metar =~ "KLAX "
  end

  @tag :timing
  test "updates on a schedule", %{bypass: bypass, bypass_domain: bypass_domain} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "#{DateTime.utc_now()}")
    end)

    update_interval_ms = 100

    {:ok, server} =
      AutoUpdatingCache.start_link(
        :url_test,
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> bypass_domain end,
          transform: fn body -> {:ok, body} end,
          update_timeout: update_interval_ms
        }
      )

    {:ok, initial_result} = AutoUpdatingCache.get(server)
    assert is_binary(initial_result)

    Process.sleep(update_interval_ms * 4)

    assert {:ok, updated_result} = AutoUpdatingCache.get(server)
    assert is_binary(updated_result)
    assert initial_result != updated_result
  end

  @tag :capture_log
  @tag :timing
  test "copes with error in update", %{bypass: bypass, bypass_domain: bypass_domain} do
    OkayWeather.Env.put_env(:fetch_before_startup?, true)

    update_interval_ms = 100
    initial_time = DateTime.utc_now() |> to_string()

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, initial_time)
    end)

    {:ok, server} =
      AutoUpdatingCache.start_link(
        :update_test,
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> bypass_domain end,
          transform: fn body -> {:ok, body} end,
          update_timeout: update_interval_ms
        }
      )

    assert {:ok, ^initial_time} = AutoUpdatingCache.get(server)

    test_failure = fn expected_time ->
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 500, "Internal Server Error")
      end)

      Process.sleep(round(update_interval_ms * 1.5))

      assert {:ok, ^expected_time} = AutoUpdatingCache.get(server)
      expected_time
    end

    test_success = fn prev_time ->
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, DateTime.utc_now() |> to_string())
      end)

      Process.sleep(round(update_interval_ms * 1.5))

      assert {:ok, updated_time} = AutoUpdatingCache.get(server)
      assert updated_time != prev_time
      updated_time
    end

    Enum.shuffle([test_failure, test_failure, test_success, test_success])
    |> Enum.reduce(initial_time, fn test_fn, prev_time ->
      test_fn.(prev_time)
    end)
  end

  test "doesn't crash on unknown messages" do
    OkayWeather.Env.put_env(:fetch_before_startup?, false)

    {:ok, server} =
      AutoUpdatingCache.start_link(
        :unknown_message_test,
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> "http://localhost" end,
          transform: fn body -> {:ok, body} end,
          update_timeout: :infinity
        }
      )

    send(server, :unknown_message)
    :sys.get_state(server)
    assert Process.alive?(server)
  end
end
