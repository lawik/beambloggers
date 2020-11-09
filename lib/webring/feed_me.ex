defmodule Webring.FeedMe do
  use GenServer

  require Logger

  # hourly
  @check_interval 1000 * 60 * 60

  def start_link(_) do
    GenServer.start_link(Webring.FeedMe, nil, name: Webring.FeedMe)
  end

  def list_feeds do
    GenServer.call(Webring.FeedMe, :list)
  end

  @impl true
  def init(nil) do
    sites = Webring.Site.list_sites()

    state = %{
      sites: sites,
      feeds: %{}
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
  def handle_info(:check, state) do
    state = check(state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:update, hash, feed}, %{feeds: feeds} = state) do
    feeds = Map.put(feeds, hash, feed)
    {:noreply, %{state | feeds: feeds}}
  end

  def schedule_check() do
    Process.send_after(self(), :check, @check_interval)
  end

  def check_rss(site) do
    body = request_url(site.url, site.url)
    rss_url = find_rss(body, site.url)

    Logger.info("URL: #{site.url}")

    if is_nil(rss_url) do
      Logger.info("No RSS URL found")
    else
      Logger.info("RSS URL: #{rss_url}")
    end

    if rss_url do
      rss_feed = request_url(site.url, rss_url)

      if rss_feed != "" do
        feed = parse_feed(rss_feed)

        if not is_nil(feed) do
          title = feed["title"]
          Logger.info("Parsing seems okay, found title: #{title}")

          # items
          ## title, description, pub_date, link, guid

          items =
            Enum.map(feed["items"], fn item ->
              {datetime, iso} =
                case Timex.parse(item["pub_date"], "{RFC1123}") do
                  {:ok, dt} -> {dt, Timex.format!(dt, "{ISO:Extended}")}
                  _ -> {nil, nil}
                end

              %{
                title: item["title"],
                description: item["description"],
                datetime: datetime,
                iso_datetime: iso,
                url: item["link"]
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

          item_count = Enum.count(items)
          Logger.info("Items parse: #{item_count}")
          %{title: title, items: items}
        else
          nil
        end
      else
        nil
      end
    else
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
    case FastRSS.parse(feed) do
      {:ok, rss} ->
        rss

      error ->
        Logger.info("An error occurred in feed parsing: #{inspect(error)}")
        nil
    end
  end

  defp find_rss(body, url) do
    case Floki.parse_document(body) do
      {:ok, doc} ->
        Floki.find(doc, "link[type=\"application/rss+xml\"")
        |> Enum.find_value(fn {_link, attrs, _} ->
          rss_path =
            Enum.find_value(attrs, fn {key, value} ->
              if key == "href", do: value, else: false
            end)

          # Some are relative, fix that
          rss_url =
            case rss_path do
              "/" <> _ = path -> Path.join(url, path)
              "http" <> _ = url -> url
              _ -> nil
            end

          rss_url
        end)

      error ->
        Logger.info("Parsing failed for URL #{url}: #{inspect(error)}")
        nil
    end
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
        response.body

      error ->
        Logger.info("Failed to request URL #{url}, error: #{inspect(error)}")
        ""
    end
  end

  defp handle_redirect(base_url, url, headers) do
    new_url =
      Enum.find_value(headers, fn {key, value} ->
        key == "location" && value
      end)

    if not is_nil(new_url) do
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
    else
      ""
    end
  end
end
