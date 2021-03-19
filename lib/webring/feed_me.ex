defmodule Webring.FeedMe do
  @moduledoc """

  Collects RSS feeds from member sites and put them together in one single feed.

  """
  use GenServer

  require Logger

  alias Webring.FeedMe.Aggregate

  # hourly
  @check_interval 1000 * 60 * 60

  # API
  def start_link(_) do
    GenServer.start_link(Webring.FeedMe, nil, name: Webring.FeedMe)
  end

  def list_feeds do
    GenServer.call(Webring.FeedMe, :list)
  end

  # GenServer Implementation
  def get_rss do
    GenServer.call(Webring.FeedMe, :rss)
  end

  @impl true
  def init(nil) do
    sites = Webring.Site.list_sites()

    feed_datetime =
      "Etc/UTC"
      |> Timex.now()
      |> Timex.format!("{RFC1123}")

    aggregated_feed =
      Aggregate.new_feed(
        "Beambloggers Webring",
        "https://beambloggers.com/feed",
        "A collection of our webring members posts in an aggregated RSS feed. Please check out their blog posts :)",
        feed_datetime,
        "en-us"
      )

    state = %{
      sites: sites,
      feeds: %{},
      feed_data: aggregated_feed,
      feed_string: Aggregate.render(aggregated_feed)
    }

    state = check(state)
    schedule_check()
    {:ok, state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state.feeds, state}
  end

  @impl true
  def handle_call(:rss, _from, state) do
    {:reply, state.feed_string, state}
  end

  @impl true
  def handle_info(:check, state) do
    state = check(state)
    schedule_check()
    {:noreply, state}
  end

  @impl true
  def handle_info({:update, hash, feed}, %{feeds: feeds, feed_data: agg} = state) do
    agg =
      Enum.reduce(feed.items, agg, fn item, agg ->
        Aggregate.update_item(
          agg,
          item.guid,
          item.title,
          item.description,
          item.rfc_datetime,
          item.url,
          feed.title
        )
      end)

    feeds = Map.put(feeds, hash, feed)
    feed_render = Aggregate.render(agg)
    {:noreply, %{state | feeds: feeds, feed_data: agg, feed_string: feed_render}}
  end

  def schedule_check() do
    Process.send_after(self(), :check, @check_interval)
  end

  def check_rss(site) do
    {:ok, body} = request_url(site.url, site.url)

    Logger.info("URL: #{site.url}")

    with {:ok, rss_url} <- find_rss(body, site.url),
         {:ok, rss_feed_body} <- request_url(site.url, rss_url),
         {:ok, feed} <- parse_feed(rss_feed_body) do
      Logger.info("RSS URL: #{rss_url}")
      Logger.info("Parsing seems okay, found title: #{feed.title}")

      # entries
      ## title, description, pub_date, link, guid
      entries =
        Enum.map(feed.entries, fn item ->
          {datetime, iso} =
            case Timex.parse(item.updated, "{RFC1123}") do
              {:ok, dt} ->
                {dt, Timex.format!(dt, "{ISO:Extended}")}

              {:error, "Expected `weekday abbreviation` at line 1, column 1."} ->
                {NaiveDateTime.from_iso8601!(item.updated), item.updated}

              _ ->
                {nil, nil}
            end

          %{
            title: item.title,
            guid: item.id,
            description: item.summary,
            rfc_datetime: item.updated,
            datetime: datetime,
            iso_datetime: iso,
            url: item.link
          }
        end)
        |> Enum.filter(fn item ->
          item.datetime
        end)
        |> Enum.sort_by(
          fn item ->
            item.iso_datetime
          end,
          :desc
        )

      entry_count = Enum.count(entries)
      Logger.info("Items parse: #{entry_count}")
      %{title: feed.title, items: entries}
    else
      {:error, :rss_error} ->
        Logger.info("No RSS URL found")
        nil

      {:error, :parse_error} ->
        nil

      {:error, :url_error} ->
        nil
    end
  end

  defp check(%{sites: sites} = state) do
    pid = self()

    Enum.each(sites, fn site ->
      Task.start(fn ->
        result = check_rss(site)
        result && Process.send_after(pid, {:update, site.hash, result}, 1)
      end)
    end)

    state
  end

  defp parse_feed(feed) do
    case FeederEx.parse(feed) do
      {:ok, rss, rest} ->
        unless String.trim(rest) == "" do
          Logger.info("Feed contains additional data: #{inspect(rest)}")
        end

        {:ok, rss}

      error ->
        Logger.info("An error occurred in feed parsing: #{inspect(error)}")
        {:ok, :parse_error}
    end
  end

  defp find_rss(body, url) do
    case Floki.parse_document(body) do
      {:ok, doc} ->
        rss_url = find_rss_link(doc, url  )

        {:ok, rss_url}

      error ->
        Logger.info("Parsing failed for URL #{url}: #{inspect(error)}")
        {:error, :rss_error}
    end
  end

  defp find_rss_link(doc, url) do
    with [] <- Floki.find(doc, "link[type=\"application/rss+xml\"") do
      Floki.find(doc, "link[type=\"application/atom+xml\"")
    end
    |> Enum.find_value(fn link ->
      extract_rss_url(link, url)
    end)
  end

  defp extract_rss_url({_link, attrs, _}, url) do
      Enum.find_value(attrs, fn {key, value} ->
        # Some are relative, fix that
        if key == "href", do: URI.merge(url, value), else: nil
      end)
  end

  defp request_url(_base_url, nil) do
    {:error, :url_error}
  end

  defp request_url(base_url, url) do
    request = Finch.build(:get, url)

    case Finch.request(request, :default) do
      {:ok, %{status: 302, headers: headers}} ->
        Logger.info("Redirect 302 at: #{url}")
        handle_redirect(base_url, url, headers)

      {:ok, %{status: 301, headers: headers}} ->
        Logger.info("Redirect 301 at: #{url}")
        handle_redirect(base_url, url, headers)

      {:ok, response} ->
        {:ok, response.body}

      error ->
        Logger.info("Failed to request URL #{url}, error: #{inspect(error)}")
        {:error, :url_error}
    end
  end

  defp handle_redirect(base_url, url, headers) do
    new_url =
      Enum.find_value(headers, fn {key, value} ->
        key == "location" && value
      end)

    if is_nil(new_url) do
      ""
    else
      new_url =
        if String.starts_with?(new_url, "http") do
          new_url
        else
          pre = String.trim_trailing(base_url, "/")
          post = String.trim_leading(new_url, "/")
          pre <> "/" <> post
        end

      if new_url == url do
        ""
      else
        request_url(base_url, new_url)
      end
    end
  end
end
