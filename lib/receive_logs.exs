defmodule ReceiveLogs do
  def wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts("[x] Received #{payload}")
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
Exchange.declare(channel, "logs", :fanout)
{:ok, %{queue: queue_name}} = Queue.declare(channel, "", exclusive: true)
Queue.bind(channel, queue_name, "logs")
Basic.consume(channel, queue_name, nil, no_ack: true)
IO.puts("[*] Waiting for messages. To exit press CTRL+C, CTRL+C")
ReceiveLogs.wait_for_messages(channel)
