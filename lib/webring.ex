defmodule Webring do
  require Logger

  @site_dir "priv/sites"
  @index_file "priv/generated/index.html"
  @style_file "priv/static/style.css"
  @integration_snippet "priv/integration/webring.min.html"

  def start(_type, _args) do
    dispatch_config = build_dispatch_config()

    port = System.get_env("PORT", "5555") |> String.to_integer()
    Logger.info("Starting on port: #{port}")

    Webring.generate_index_file()

    {:ok, _} =
      :cowboy.start_clear(
        :http,
        [{:port, port}],
        %{env: %{dispatch: dispatch_config}}
      )

    Webring.Supervisor.start_link(name: Webring.Supervisor)
  end

  def build_dispatch_config do
    :cowboy_router.compile([
      {:_,
       [
         {"/", :cowboy_static, {:file, @index_file}},
         {"/style.css", :cowboy_static, {:file, @style_file}},
         {"/shuffle", Webring.Handler, []},
         {"/integration", :cowboy_static, {:file, @integration_snippet}}
       ]}
    ])
  end

  def generate_index_file do
    contents =
      File.ls!(@site_dir)
      |> Enum.map(fn filename ->
        @site_dir
        |> Path.join(filename)
        |> File.read!()
        |> String.split("\n\n")
        |> site_to_html()
      end)
      |> Enum.join()

    contents = site_template(contents)

    with :ok <- File.mkdir_p!(Path.dirname(@index_file)) do
      File.write!(@index_file, contents)
    end
  end

  defp site_to_html([url, title, blurb]) do
    """
    <div class="site">
    <h2>#{title}</h2>
    <a class="link" href="#{url}">#{url}</a>
    <p>#{blurb}</p>
    </div>
    """
  end

  defp site_to_html(site_data) do
    Logger.warn("Invalid site: #{site_data}")
    ""
  end

  defp site_template(contents) do
    """
    <html>
      <head>
        <title>Beam Bloggers Webring</title>
        <link rel="stylesheet" type="text/css" href="/style.css" />
      </head>
      <body>
      <h1>Beam Bloggers Webring</h1>
      <p>If you have a blog that regularly covers Elixir, Erlang, the BEAM or any related topics do <a href="https://github.com/lawik/beambloggers">join the webring</a>.</p>
      #{contents}
      </body>
    </html>
    """
  end
end
