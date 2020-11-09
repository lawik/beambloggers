defmodule Webring.FairChance do
  use GenServer

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

  @impl true
  def handle_call(:list_sites, _from, {_, _, site_list} = state) do
    {:reply, site_list, state}
  end

  def rotate do
    GenServer.call(Webring.FairChance, :rotate)
  end

  def list_sites do
    GenServer.call(Webring.FairChance, :list_sites)
  end

  defp build_site_rotation do
    Webring.Site.list_sites()
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
