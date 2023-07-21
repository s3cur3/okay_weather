defmodule OkayWeather.AutoUpdatingCache do
  @moduledoc """
  Regularly tries to fetch the latest data from a URL.
  Things never actually get deleted from the cache...
  Instead we just keep trying to update them in the background.
  """
  use GenServer
  require Logger
  alias OkayWeather.AutoUpdatingCache.State

  @spec start_link(atom, State.url_generator(), State.transform(), integer) ::
          GenServer.on_start()
  def start_link(name, url_generator, transform, update_ms \\ :timer.minutes(5))
      when is_atom(name) and is_function(url_generator, 1) and is_function(transform, 1) and
             is_integer(update_ms) do
    initial_state = %State{
      url_generator: url_generator,
      transform: transform,
      update_timeout: update_ms
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
    spawn_update(state, self())
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:lookup, _from, %State{parsed_content: nil} = state) do
    Logger.warn("No data yet for #{State.url(state)}")
    {:reply, :error, state}
  end

  def handle_call(:lookup, _from, %State{parsed_content: parsed_content} = state) do
    {:reply, parsed_content, state}
  end

  @impl GenServer
  def handle_info(:update, %State{} = state) do
    spawn_update(state, self())
    {:noreply, state}
  end

  def handle_info({:state_updated, %State{} = new_state}, _prev_state) do
    {:ok, _timer_id} = :timer.send_after(new_state.update_timeout, :update)
    {:noreply, new_state}
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
            # TODO: If we fail to update, try to get it from the disk cache.
            # If there's no disk cache, try an hour ago, then two hours ago, then four hours ago.
            Logger.info("Failed to fetch #{State.url(state)} with error: #{inspect(err)}")
            state
        end

      send(pid, {:state_updated, new_state})
    end)
  end

  defp via_tuple(name) when is_atom(name), do: {:via, Registry, {__MODULE__, name}}
end
