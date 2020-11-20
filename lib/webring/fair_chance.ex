defmodule Webring.FairChance do
  use GenServer

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def rotate do
    GenServer.call(__MODULE__, :rotate)
  end

  def list_sites do
    GenServer.call(__MODULE__, :list_sites)
  end

  # GenServer Implementation
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

  defp build_site_rotation do
    Webring.Site.get_sites()
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
