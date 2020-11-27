defmodule WebringWeb.PageController do
  use WebringWeb, :controller

  @latest_limit 12

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
      |> Enum.take(@latest_limit)

    sites =
      sites
      |> Enum.sort_by(
        fn site ->
          feed = feeds[site.hash]

          if not is_nil(feed) and feed.items != [] do
            [latest | _] = feed.items
            latest[:iso_datetime]
          else
            # bump to bottom sorting if no RSS or items
            "2001" <> site.hash
          end
        end,
        :desc
      )

    render(conn, "index.html", %{sites: sites, feeds: feeds, latest: latest})
  end

  def rss(conn, _params) do
    feed_xml = Webring.FeedMe.get_rss()

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, feed_xml)
  end
end
