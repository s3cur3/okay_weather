import Config

config :okay_weather,
  # Delay the application startup while trying to fetch the latest weather data?
  # (Details below.)
  fetch_before_startup?: false,
  # How long should we wait between polling for new data?
  update_timeout: :infinity

config :logger, level: :info
