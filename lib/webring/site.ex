defmodule Webring.Site do
  defstruct hash: nil, title: nil, url: nil, description: nil, fancy_body: nil

  alias Webring.Site

  @site_dir Path.join("priv", "sites")
  @site_files File.ls!(@site_dir)

  def get_sites() do
    @site_files
    |> Enum.map(&new_site/1)
    |> Enum.filter(fn %{url: url, fancy_body: fancy} ->
      uri = URI.parse(url)
      uri.scheme != nil and uri.host =~ "." and fancy
    end)
  end

  # mark sites as external resources
  for site_file <- @site_files do
    @external_resource @site_dir |> Path.join(site_file) |> Path.relative_to_cwd()
  end

  defp new_site(filename) do
    data = File.read!(Path.join(@site_dir, filename))
    [url, title, blurb] = String.split(data, "\n\n", parts: 3)
    site_hash = :crypto.hash(:md5, filename <> data) |> Base.encode16()

    fancy =
      case Earmark.as_html(blurb) do
        {:ok, html, _} -> html
        _ -> nil
      end

    %__MODULE__{title: title, url: url, hash: site_hash, description: blurb, fancy_body: fancy}
  end

  def __mix_recompile__? do
    @site_dir |> File.ls!() |> :erlang.md5() !=
      :erlang.md5(@site_files)
  end

  # TODO: Remove me once we require Elixir v1.11+.
  def __phoenix_recompile__?, do: __mix_recompile__?()

  def hash(filename, data) do
    :crypto.hash(:md5, filename <> data) |> Base.encode16()
  end

  def list_sites do
    get_sites()
    |> Enum.map(fn site ->
      Enum.reduce(site, %__MODULE__{}, fn {key, value}, site ->
        Map.put(site, key, value)
      end)
    end)
  end
end
