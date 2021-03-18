defmodule Webring.Site do
  @moduledoc """

  Generates list of sites from textfiles in sites folder

  """
  defstruct hash: nil, title: nil, url: nil, description: nil, fancy_body: nil

  alias Webring.Site

  @site_dir Path.join("priv", "sites")
  @site_files File.ls!(@site_dir)
  @sites @site_files
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

  # mark sites as external resources
  for site_file <- @site_files do
    @external_resource @site_dir |> Path.join(site_file) |> Path.relative_to_cwd()
  end

  def __mix_recompile__? do
    @site_dir |> File.ls!() |> :erlang.md5() !=
      :erlang.md5(@site_files)
  end


  def hash(filename, data) do
    :crypto.hash(:md5, filename <> data) |> Base.encode16()
  end

  # ordered list of sites determined at compile time, order should only change if logic changes
  # additions/deletions can happen but don't change the order
  def list_sites do
    @sites
    |> Enum.map(fn site ->
      Enum.reduce(site, %Site{}, fn {key, value}, site ->
        Map.put(site, key, value)
      end)
    end)
  end
end
