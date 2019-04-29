defmodule FibServer do
  alias AMQP.Basic

  def fib(0), do: 0
  def fib(1), do: 1
  def fib(n) when n > 1, do: fib(n - 1) + fib(n - 2)

  def wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        {n, _} = Integer.parse(payload)
        IO.puts("[.] fib(#{n})")

        Basic.publish(channel, "", meta.reply_to, n |> fib() |> Integer.to_string(),
          correlation_id: meta.correlation_id
        )

        Basic.ack(channel, meta.delivery_tag)
        wait_for_messages(channel)
    end
  end
end

alias AMQP.{
  Basic,
  Channel,
  Connection,
  Queue
}

{:ok, connection} = Connection.open()
{:ok, channel} = Channel.open(connection)
Queue.declare(channel, "rpc_queue")
Basic.qos(channel, prefetch_count: 1)
Basic.consume(channel, "rpc_queue")
IO.puts("[x] Awaiting RPC requests")
FibServer.wait_for_messages(channel)
