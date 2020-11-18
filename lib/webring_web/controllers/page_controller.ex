defmodule WebringWeb.PageController do
  use WebringWeb, :controller

  def index(conn, _params) do
    sites = Webring.Site.list_sites()
    feeds = Webring.FeedMe.list_feeds()

    latest =
      feeds
      |> Enum.filter(fn {_, feed} ->
        Enum.count(feed.items) > 0
      end)
      |> Enum.map(fn {site_hash, %{items: [item | _]}} ->
        site =
          Enum.find(sites, fn site ->
            site.hash == site_hash
          end)

        %{item: item, site: site}
      end)
      |> Enum.sort_by(
        fn entry ->
          entry.item[:iso_datetime]
        end,
        :desc
      )

    render(conn, "index.html", %{sites: sites, feeds: feeds, latest: latest})
  end
end
