defmodule OkayWeather.AutoUpdatingUrlCacheTest do
  use ExUnit.Case, async: true
  alias OkayWeather.AutoUpdatingUrlCache

  setup do
    bypass = Bypass.open()
    bypass_domain = "http://localhost:#{bypass.port}"

    %{bypass: bypass, bypass_domain: bypass_domain}
  end

  test "works with simple URLs", %{bypass: bypass, bypass_domain: bypass_domain} do
    Bypass.expect_once(bypass, "GET", "/", fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(metadata))
    end)

    {:ok, server} = AutoUpdatingUrlCache.start_link(:bypass, fn _ -> bypass_domain end)

    %HTTPoison.Response{status_code: 200, headers: headers1, body: _} =
      AutoUpdatingUrlCache.get(server)

    cache_time1 = cached_at(headers1)

    %HTTPoison.Response{status_code: 200, headers: headers2, body: _} =
      AutoUpdatingUrlCache.get(server)

    assert cache_time1 == cached_at(headers2), "Cache should not have updated"
  end

  test "updates timestamps on change" do
    random_generator =
      "https://www.random.org/strings/?num=1&len=8&digits=on&upperalpha=on&loweralpha=on&unique=on&rnd=new&format=plain"

    {:ok, server} =
      AutoUpdatingUrlCache.start_link(
        :random_dot_org,
        fn _ -> random_generator end,
        1
      )

    %HTTPoison.Response{status_code: 200, headers: headers1, body: _} =
      AutoUpdatingUrlCache.get(server)

    {:ok, cache_time1, 0} = DateTime.from_iso8601(cached_at(headers1))

    Process.sleep(100)

    %HTTPoison.Response{status_code: 200, headers: headers2, body: _} =
      AutoUpdatingUrlCache.get(server)

    {:ok, cache_time2, 0} = DateTime.from_iso8601(cached_at(headers2))
    assert DateTime.compare(cache_time1, cache_time2) == :lt, "Cache should have updated"
  end

  test "does not update timestamps when there is no change" do
    {:ok, server} =
      AutoUpdatingUrlCache.start_link(
        :apple,
        fn _ -> "https://www.apple.com/legal/privacy/en-ww/" end,
        1
      )

    %HTTPoison.Response{status_code: 200, headers: headers1, body: _} =
      AutoUpdatingUrlCache.get(server)

    {:ok, cache_time1, 0} = DateTime.from_iso8601(cached_at(headers1))

    Process.sleep(100)

    %HTTPoison.Response{status_code: 200, headers: headers2, body: _} =
      AutoUpdatingUrlCache.get(server)

    {:ok, cache_time2, 0} = DateTime.from_iso8601(cached_at(headers2))

    assert DateTime.compare(cache_time1, cache_time2) == :eq,
           "It's extremely unlike Apple changed their privacy policy in the last 100 ms"
  end

  defp cached_at(headers), do: headers |> Enum.find(fn {k, _} -> k == "cached-at" end) |> elem(1)
end
