defmodule Webring.FairChance do
    use GenServer

    def start_link do
        GenServer.start_link(Webring.FairChance, nil)
    end

    @impl true
    def init(nil) do
    
    end
end