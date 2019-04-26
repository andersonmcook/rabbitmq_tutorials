defmodule ReceiveLogsTopic do
  def wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        IO.puts("[x] Received [#{meta.routing_key}] #{payload}")
        wait_for_messages(channel)
    end
  end
end

alias AMQP.{
  Basic,
  Channel,
  Connection,
  Exchange,
  Queue
}

{:ok, connection} = Connection.open()
{:ok, channel} = Channel.open(connection)

Exchange.declare(channel, "topic_logs", :topic)

{:ok, %{queue: queue_name}} = Queue.declare(channel, "", exclusive: true)

if System.argv() == [] do
  IO.puts("Usage: mix run lib/receive_logs_topic.exs [binding_key]...")
  System.halt(1)
end

for binding_key <- System.argv() do
  Queue.bind(channel, queue_name, "topic_logs", routing_key: binding_key)
end

Basic.consume(channel, queue_name, nil, no_ack: true)

IO.puts("[*] Waiting for messages. To exit press CTRL+C, CTRL+C")

ReceiveLogsTopic.wait_for_messages(channel)
