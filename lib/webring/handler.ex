defmodule Webring.Handler do
  @default_headers %{"content-type" => "text/html"}
  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
    response =
      :cowboy_req.reply(
        200,
        @default_headers,
        "hello world",
        request
      )

    {:ok, response, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end
end
