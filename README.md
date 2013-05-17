soccazzi - Elixir websockets
============================
Simple evented library to create websocket services, it's all implemented
in Elixir and uses the [socket][1] library implementation of websockets.

It's just a thin evented wrapper around it, every connection is in its own
process.

Example
-------

```elixir
defmodule Test do
  use Soccazzi

  def connect(sock, table) do
    :ets.insert(table, { sock.remote!, sock })

    IO.puts "Connected: #{inspect sock.remote!}"

    table
  end

  def message(sock, table, msg) do
    IO.puts "Message: #{inspect msg}"

    table
  end

  def disconnect(sock, table) do
    :ets.delete(table, sock.remote!)

    IO.puts "Disconnected: #{inspect sock.remote!}"
  end
end

t = :ets.new(:lol, [:public])
Test.start t, port: 5664
```

This example will start a websocket service and keep the list of running
instances in the provided ets table, you could then access that list and send
messages to the various clients.
