defmodule Webring do
  require Logger

  @site_dir "priv/sites"
  @index_file "priv/generated/index.html"

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
         {"/shuffle", Webring.Handler, []}
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

    File.write!(@index_file, contents)
  end

  defp site_to_html([url, title, blurb]) do
    """
    <h2>#{title}</h2>
    <a href="#{url}">#{url}</a>
    <p>#{blurb}</p>
    """
  end

  defp site_to_html(site_data) do
    Logger.warn("Invalid site: #{site_data}")
    ""
  end

  defp site_template(contents) do
    """
    <html>
      <head><title>Beam Bloggers Webring</title></head>
      <body>
      <h1>Beam Bloggers Webring</h1>
      #{contents}
      </body>
    </html>
    """
  end
end
