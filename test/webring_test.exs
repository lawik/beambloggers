defmodule WebringTest do
  use ExUnit.Case
  doctest Webring

  test "fair chance is fair" do
    assert spin() == :fair
  end

  defp spin do
    site = Webring.FairChance.rotate()
    spin([], site)
  end

  defp spin(seen, start) do
    if start in seen do
      if length(Enum.uniq(seen)) == length(seen) do
        :fair
      else
        :unfair
      end
    else
      site = Webring.FairChance.rotate()
      spin([site | seen], start)
    end
  end
end
