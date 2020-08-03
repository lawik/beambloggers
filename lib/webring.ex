defmodule Webring do
  require Logger

  def start(_type, _args) do
    dispatch_config = build_dispatch_config()

    port = System.get_env("PORT", "5555") |> String.to_integer()
    Logger.info("Starting on port: #{port}")

    {:ok, _} =
      :cowboy.start_clear(
        :http,
        [{:port, port}],
        %{env: %{dispatch: dispatch_config}}
      )
  end

  def build_dispatch_config do
    :cowboy_router.compile([
      {:_,
       [
         {"/", Webring.Handler, []}
       ]}
    ])
  end
end
