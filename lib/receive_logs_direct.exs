defmodule ReceiveLogsDirect do
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

severities =
  System.argv()
  |> OptionParser.parse!(strict: Keyword.new([:error, :info, :warning], &{&1, :boolean}))
  |> Kernel.elem(0)

Exchange.declare(channel, "direct_logs", :direct)

{:ok, %{queue: queue_name}} = Queue.declare(channel, "", exclusive: true)

for {severity, true} <- severities do
  Queue.bind(channel, queue_name, "direct_logs", routing_key: Atom.to_string(severity))
end

Basic.consume(channel, queue_name, nil, no_ack: true)

IO.puts("[*] Waiting for messages. To exit press CTRL + C, CTRL + C")

ReceiveLogsDirect.wait_for_messages(channel)
