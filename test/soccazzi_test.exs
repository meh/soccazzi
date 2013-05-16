Code.require_file "test_helper.exs", __DIR__

defmodule SoccazziTest do
  use ExUnit.Case

  defmodule Test do
    use Soccazzi

    def open(sock) do
      []
    end

    def message(sock, state, msg) do
      [msg | state]
    end

  end

  test "something" do
    Test.start
  end
end
