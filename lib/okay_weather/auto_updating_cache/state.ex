defmodule OkayWeather.AutoUpdatingCache.State do
  use TypedStruct

  @type url_generator :: (DateTime.t() -> String.t())
  @type transform :: (String.t() -> {:ok, any} | {:error, any})

  typedstruct enforce: true do
    field :url_generator, url_generator()
    field :transform, transform()
    field :update_timeout, timeout()
    field :raw_content, String.t() | nil, default: nil
    field :parsed_content, any, default: nil
  end

  def url(%__MODULE__{} = state, for_time \\ DateTime.utc_now()) do
    state.url_generator.(for_time)
  end

  @spec update(t()) :: {:ok, t()} | {:error, any}
  def update(%__MODULE__{} = state, for_time \\ DateTime.utc_now()) do
    current_url = url(state, for_time)

    with {:ok, raw} <- fetch(current_url),
         {:ok, parsed} <- state.transform.(raw) do
      {:ok, %{state | raw_content: raw, parsed_content: parsed}}
    end
  end

  defp fetch(url) when is_binary(url) do
    case HTTPoison.get(url, [], follow_redirect: true, recv_timeout: 60_000) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status < 300 -> {:ok, body}
      err -> err
    end
  end
end
