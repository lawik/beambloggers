defmodule Webring.FairChance do
  use GenServer

  @site_dir "priv/sites"

  def start_link(_) do
    GenServer.start_link(Webring.FairChance, nil, name: Webring.FairChance)
  end

  @impl true
  def init(nil) do
    sorted_sites = build_site_rotation()
    {:ok, {sorted_sites, [], sorted_sites}}
  end

  @impl true
  def handle_call(:rotate, _from, state) do
    {site, state} = rotate_next(state)
    {:reply, site, state}
  end

  def rotate do
    GenServer.call(Webring.FairChance, :rotate)
  end

  defp hash(filename, data) do
    :crypto.hash(:md5, filename <> data) |> Base.encode16()
  end

  defp is_valid_url?({_, url}) do
    uri = URI.parse(url)
    uri.scheme != nil and uri.host =~ "."
  end

  defp build_site_rotation do
    File.ls!(@site_dir)
    |> Enum.map(fn filename ->
      data = File.read!(Path.join(@site_dir, filename))
      [url | _] = String.split(data)
      site_hash = hash(filename, data)
      {site_hash, url}
    end)
    |> Enum.filter(&is_valid_url?/1)
    |> Enum.sort()
  end

  defp rotate_next(state) do
    case state do
      {[], sites, list} ->
        sites = Enum.reverse(sites)
        [site | sites] = sites
        {site, {sites, [site], list}}

      {[site | sites], rotated, list} ->
        {site, {sites, [site | rotated], list}}
    end
  end
end
