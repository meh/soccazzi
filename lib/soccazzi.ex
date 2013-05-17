defmodule Soccazzi do
  use Behaviour

  defcallback verify(Socket.Web.t) :: boolean
  defcallback connect(Socket.Web.t, term) :: term
  defcallback message(Socket.Web.t, term, String.t) :: term
  defcallback text(Socket.Web.t, term, String.t) :: term
  defcallback binary(Socket.Web.t, term, binary) :: term
  defcallback close(Socket.Web.t, term, atom) :: term
  defcallback error(Socket.Web.t, term, term) :: term
  defcallback disconnect(Socket.Web.t, term) :: term

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Soccazzi

      def start do
        start(nil, [])
      end

      def start(options) do
        start(nil, options)
      end

      def start(state, options) do
        port   = Keyword.get(options, :port, 80)
        socket = Socket.Web.listen!(port, options)

        if options[:acceptors] do
          Enum.map 1 .. options[:acceptors], fn _ ->
            spawn __MODULE__, :acceptor, [socket, state]
          end
        else
          spawn __MODULE__, :acceptor, [socket, state]
        end
      end

      defoverridable start: 0, start: 1, start: 2

      def acceptor(socket, state) do
        case socket.accept verify: function(verify/1) do
          { :ok, client } ->
            spawn __MODULE__, :handle, [client, connect(client, state)]

          { :error, nil } ->
            nil
        end

        acceptor(socket, state)
      end

      def handle(socket, state) do
        close = false

        case socket.recv do
          { :ok, { :text, data } } ->
            state = text(socket, state, data)
            state = message(socket, state, data)

          { :ok, { :binary, data } } ->
            state = binary(socket, state, data)
            state = message(socket, state, data)

          { :ok, { :ping, data } } ->
            socket.pong(data)

          { :ok, :close } ->
            state = close(socket, state, nil)
            state = disconnect(socket, state)

            socket.close
            close = true

          { :ok, { :close, reason, data } } ->
            state = close(socket, state, { reason, data })
            state = disconnect(socket, state)

            socket.close
            close = true

          { :error, reason } ->
            state = error(socket, state, reason)
            state = disconnect(socket, state)

            socket.abort
            close = true
        end

        unless close do
          handle(socket, state)
        end
      end

      def message(socket, text) do
        socket.send({ :text, text })
      end

      def close(socket, reason) do
      end

      ## defaults

      def verify(_) do
        true
      end

      defoverridable verify: 1

      def connect(_) do
        nil
      end

      defoverridable connect: 1

      def message(_, state, _) do
        state
      end

      defoverridable message: 3

      def binary(_, state, _) do
        state
      end

      defoverridable binary: 3

      def text(_, state, _) do
        state
      end

      defoverridable text: 3

      def close(_, state, _) do
        state
      end

      defoverridable close: 3

      def error(_, state, _) do
        state
      end

      defoverridable error: 3

      def disconnect(_, state) do
        state
      end

      defoverridable disconnect: 2
    end
  end
end
