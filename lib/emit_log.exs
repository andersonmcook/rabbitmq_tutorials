alias AMQP.{
  Basic,
  Channel,
  Connection,
  Exchange
}

{:ok, connection} = Connection.open()
{:ok, channel} = Channel.open(connection)

message =
  case System.argv() do
    [] -> "Hello World"
    words -> Enum.join(words, " ")
  end

Exchange.declare(channel, "logs", :fanout)
Basic.publish(channel, "logs", "", message)
IO.puts("[x] Sent '#{message}'")
Connection.close(connection)
