defmodule Webring.Handler do
  @default_headers %{"content-type" => "text/html"}
  def init(req, state) do
    handle(req, state)
  end

  def handle(%{path: "/shuffle"} = request, state) do
    {_, url} = Webring.FairChance.rotate()
    response =
      :cowboy_req.reply(
        302,
        Map.put(@default_headers, "location", url),
        "",
        request
      )

    {:ok, response, state}
  end

  def handle(request, state) do
    response =
      :cowboy_req.reply(
        200,
        @default_headers,
        "<h1>Beam Bloggers Webring</h1>",
        request
      )

    {:ok, response, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end
end
