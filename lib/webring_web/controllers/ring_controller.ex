defmodule WebringWeb.RingController do
  use WebringWeb, :controller
  require Logger

  def random(conn, _params) do
    random_url =
      Webring.Site.list_sites()
      |> Enum.random()
      |> ring_url()

    redirect(conn, external: random_url)
  end

  def next(conn, params), do: relative(conn, params, +1)
  def prev(conn, params), do: relative(conn, params, -1)

  defp relative(conn, params, rel) do
    referer =
      case Map.get(params, "referer") do
        nil -> hd(get_req_header(conn, "referer"))
        ref -> "https://#{ref}"
      end

    # we trust that the sites are ordered according to ""logic"" in Webring.Site.list_sites/0 :-)
    url =
      Webring.Site.list_sites()
      |> find_relative(referer, rel)
      |> ring_url()

    redirect(conn, external: url)
  end

  defp ring_url(site) do
    site
    |> Map.get(:url)
    |> URI.parse()
    |> URI.merge("?ref=#{WebringWeb.Endpoint.host()}")
    |> URI.to_string()
  end

  defp find_relative(sites, referer, rel) do
    with index when is_integer(index) <- Enum.find_index(sites, &host_match?(&1.url, referer)),
         %Webring.Site{} = site <- Enum.at(sites, index + rel, :out_of_bounds) do
      site
    else
      :out_of_bounds ->
        # since we're circular we should grab the first
        hd(sites)

      nil ->
        Logger.info("Webring, ringmember not found: #{referer}")
        Enum.random(sites)
    end
  end

  defp host_match?(uri1, uri2) do
    uri1 = URI.parse(uri1)
    uri2 = URI.parse(uri2)
    uri1.host == uri2.host
  end
end
