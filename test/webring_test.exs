defmodule WebringTest do
  use ExUnit.Case
  doctest Webring

  test "greets the world" do
    assert Webring.hello() == :world
  end
end
