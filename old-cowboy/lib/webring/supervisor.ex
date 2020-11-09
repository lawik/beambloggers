defmodule Webring.Supervisor do
  use Supervisor

  def start_link(opts) do
    {args, opts} = Keyword.pop!(opts, :cowboy_args)
    Supervisor.start_link(__MODULE__, args, opts)
  end

  @impl true
  def init(args) do
    children = [
      Webring.FairChance,
      {Finch, name: :default},
      Webring.FeedMe,
      %{id: :cowboy, start: {:cowboy, :start_clear, args}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
