defmodule OkayWeather.AutoUpdatingCache.State do
  @moduledoc false
  alias OkayWeather.AutoUpdatingCache.Spec

  @enforce_keys [:name, :url_generator, :transform, :update_timeout]
  defstruct [
    :name,
    :url_generator,
    :transform,
    :update_timeout,
    :raw_content,
    :parsed_content,
    :fetched_at,
    :updated_for
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          url_generator: Spec.url_generator(),
          transform: Spec.transform(),
          update_timeout: timeout,
          raw_content: String.t() | nil,
          parsed_content: any() | nil,
          fetched_at: NaiveDateTime.t() | nil,
          updated_for: NaiveDateTime.t() | nil
        }

  def url(%__MODULE__{} = state, for_time \\ DateTime.utc_now()) do
    state.url_generator.(for_time)
  end

  def cache_path(%__MODULE__{} = state) do
    System.tmp_dir!() |> Path.join("#{state.name}.txt")
  end

  @spec update(t(), DateTime.t(), timeout) :: {:ok, t()} | {:error, any}
  def update(%__MODULE__{} = state, for_time \\ DateTime.utc_now(), timeout \\ 60_000) do
    current_url = url(state, for_time)
    fetched_at = NaiveDateTime.utc_now()

    with {:ok, raw} <- fetch(current_url, timeout),
         {:ok, parsed} <- state.transform.(raw) do
      File.write(cache_path(state), raw)

      updated_state = %{
        state
        | raw_content: raw,
          parsed_content: parsed,
          fetched_at: fetched_at,
          updated_for: for_time
      }

      {:ok, updated_state}
    end
  end

  defp fetch(url, timeout) when is_binary(url) do
    case Req.get(url, receive_timeout: timeout, retry: false) do
      {:ok, %{status: status, body: body}} when status < 300 -> {:ok, body}
      {:ok, %{status: _} = result} -> {:error, result}
      {:error, _} = error -> error
    end
  end
end
