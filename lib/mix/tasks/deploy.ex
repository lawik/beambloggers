defmodule Mix.Tasks.Deploy do
  @moduledoc "Build and deploy the webring over SSH"
  @shortdoc "Builds and deploys the webring over SSH"

  use Mix.Task

  # @impl Mix.Task
  # def run(args) do
  #   Job.run(
  #     Job.Pipeline.sequence([
  #       mix("compile --warnings-as-errors"),
  #       mix("test")
  #     ]),
  #     timeout: :timer.minutes(10)
  #   )
  # end
end
