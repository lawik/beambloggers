defmodule Webring.FeedMe.Aggregate do
  defstruct channel: nil, items: []

  require Logger

  alias Webring.FeedMe.Aggregate

  def new_feed(title, url, description, rfc1123_date, locale) do
    %Aggregate{
      channel: RSS.channel(title, url, description, rfc1123_date, locale),
      items: []
    }
  end

  def update_item(agg, guid, title, description, rfc1123_date, url) do
    # Should cover most cases where people have bad GUIDs
    guid = "#{url}---#{guid}"

    items =
      case rfc_to_iso(rfc1123_date) do
        {:ok, iso} ->
          items =
            Enum.reject(agg.items, fn {_iso, item_guid, _item} ->
              guid == item_guid
            end)

          rss_item = RSS.item(title, description, rfc1123_date, url, guid)
          item = {iso, guid, rss_item}
          [item | items]

        {:error, :parsing_failed} ->
          Logger.warn("Date parsing failed for: #{url} #{rfc1123_date} #{title}")
          agg.items

        _ ->
          agg.items
      end

    %{agg | items: items}
  end

  def render(agg) do
    items =
      agg.items
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.map(fn {_, _, item} -> item end)

    RSS.feed(agg.channel, items)
  end

  def rfc_to_iso(rfc_date) do
    case Timex.parse(rfc_date, "{RFC1123}") do
      {:ok, dt} ->
        Timex.format(dt, "{ISO:Extended}")

      {:error, "Expected `weekday abbreviation` at line 1, column 1."} ->
        # Assume ISO-8601, parse to fail if it doesn't work
        Timex.parse(rfc_date, "{ISO:Extended}")

      _ ->
        {:error, :parsing_failed}
    end
  end
end
