defmodule Webring.Site do
  defstruct hash: nil, title: nil, url: nil, description: nil, fancy_body: nil

  alias Webring.Site

  @site_dir "priv/sites"
  @sites File.ls!(@site_dir)
         |> Enum.map(fn filename ->
           data = File.read!(Path.join(@site_dir, filename))
           [url, title, blurb] = String.split(data, "\n\n", parts: 3)
           site_hash = :crypto.hash(:md5, filename <> data) |> Base.encode16()

           fancy =
             case Earmark.as_html(blurb) do
               {:ok, html, _} -> html
               _ -> nil
             end

           %{title: title, url: url, hash: site_hash, description: blurb, fancy_body: fancy}
         end)
         |> Enum.filter(fn %{url: url, fancy_body: fancy} ->
           uri = URI.parse(url)
           uri.scheme != nil and uri.host =~ "." and fancy
         end)

  def hash(filename, data) do
    :crypto.hash(:md5, filename <> data) |> Base.encode16()
  end

  def list_sites do
    @sites
    |> Enum.map(fn site ->
      Enum.reduce(site, %Site{}, fn {key, value}, site ->
        Map.put(site, key, value)
      end)
    end)
  end
end
