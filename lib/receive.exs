defmodule Receive do
  def wait_for_messages do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts("Received #{payload}")
        wait_for_messages()
    end
  end
end

{:ok, connection} = AMQP.Connection.open()
{:ok, channel} = AMQP.Channel.open(connection)
# Idempotent
AMQP.Queue.declare(channel, "hello")
# 3rd argument is the consumer process, defaults to self()
AMQP.Basic.consume(channel, "hello", nil, no_ack: true)
Receive.wait_for_messages()
