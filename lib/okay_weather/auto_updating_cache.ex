defmodule OkayWeather.AutoUpdatingCache do
  @moduledoc """
  Regularly tries to fetch the latest data from a URL.
  Things never actually get deleted from the cache...
  Instead we just keep trying to update them in the background.
  """
  use GenServer
  require Logger
  alias OkayWeather.AutoUpdatingCache.Spec
  alias OkayWeather.AutoUpdatingCache.State

  @spec start_link(atom, Spec.t()) :: GenServer.on_start()
  def start_link(name, %Spec{} = spec) when is_atom(name) do
    initial_state = %State{
      name: name,
      url_generator: spec.url_generator,
      transform: spec.transform,
      update_timeout: spec.update_timeout || :timer.minutes(5)
    }

    GenServer.start_link(__MODULE__, initial_state, name: via_tuple(name))
  end

  @doc """
  Looks up the server's latest cached content.
  Returns an :ok tuple if we have any cached content, or `:error` if we have no cached content.
  """
  @spec get(pid | atom) :: {:ok, any} | :error
  def get(cache_pid) when is_pid(cache_pid), do: GenServer.call(cache_pid, :lookup)

  def get(cache_name) when is_atom(cache_name) do
    GenServer.call(via_tuple(cache_name), :lookup)
  end

  ################ Server Implementation ################
  @impl GenServer
  def init(%State{} = state) do
    updated_state =
      case fetch_initial_value(state) do
        {:ok, updated_state} -> updated_state
        {:error, _} -> state
      end

    {:ok, schedule_update(updated_state)}
  end

  @impl GenServer
  def handle_call(:lookup, _from, %State{parsed_content: nil} = state) do
    Logger.warning("No data yet for #{State.url(state)}")
    {:reply, :error, state}
  end

  def handle_call(:lookup, _from, %State{parsed_content: parsed_content} = state) do
    {:reply, {:ok, parsed_content}, state}
  end

  @impl GenServer
  def handle_info(:update, %State{} = state) do
    spawn_update(state, self())
    {:noreply, state}
  end

  def handle_info({:state_updated, %State{} = updated_state}, _prev_state) do
    {:noreply, schedule_update(updated_state)}
  end

  # No-op handler for messages from async_nolink `Task`s
  def handle_info({ref, _}, socket) when is_reference(ref), do: {:noreply, socket}
  def handle_info({:DOWN, _, _, _, _}, socket), do: {:noreply, socket}

  def handle_info(msg, state) do
    Logger.debug("Unhandled AutoUpdatingCache message #{inspect(msg)}")
    {:noreply, state}
  end

  defp spawn_update(%State{} = state, pid) do
    Task.Supervisor.async_nolink(OkayWeather.FetchSupervisor, fn ->
      new_state =
        case State.update(state) do
          {:ok, updated_state} ->
            updated_state

          {:error, err} ->
            Logger.info("Failed to fetch #{State.url(state)} with error: #{inspect(err)}")
            state
        end

      send(pid, {:state_updated, new_state})
    end)
  end

  defp schedule_update(%State{update_timeout: :infinity} = state), do: state

  defp schedule_update(%State{update_timeout: timeout} = state) when timeout > 0 do
    {:ok, _timer_id} = :timer.send_after(timeout, :update)
    state
  end

  @max_hours_to_attempt 4

  @spec fetch_initial_value(State.t(), non_neg_integer(), DateTime.t()) ::
          {:ok, State.t()} | {:error, String.t()}
  defp fetch_initial_value(state, attempt \\ 0, dt \\ DateTime.utc_now())

  defp fetch_initial_value(%State{} = state, attempt, dt) when attempt < @max_hours_to_attempt do
    case State.update(state, dt, (attempt + 1) * 5_000) do
      {:ok, _updated_state} = result -> result
      _ -> fetch_initial_value(state, attempt + 1, DateTime.add(dt, -1, :hour))
    end
  end

  defp fetch_initial_value(%State{} = state, _attempt, _dt) do
    cached_content = File.read!(State.cache_path(state))
    {:ok, parsed_content} = state.transform.(cached_content)
    {:ok, %{state | raw_content: cached_content, parsed_content: parsed_content}}
  rescue
    error ->
      Logger.error("Failed to initialize cache with error: #{inspect(error)}")
      {:error, "Failed to fetch initial value after #{@max_hours_to_attempt} attempts"}
  end

  defp via_tuple(name) when is_atom(name), do: {:via, Registry, {__MODULE__, name}}
end
