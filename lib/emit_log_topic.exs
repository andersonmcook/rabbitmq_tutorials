alias AMQP.{
  Basic,
  Channel,
  Connection,
  Exchange
}

{:ok, connection} = Connection.open()
{:ok, channel} = Channel.open(connection)

{topic, message} =
  case System.argv() do
    [] -> {"anonymous.info", "Hellow World!"}
    [message] -> {"anonymous.info", message}
    [topic | words] -> {topic, Enum.join(words, " ")}
  end

Exchange.declare(channel, "topic_logs", :topic)
Basic.publish(channel, "topic_logs", topic, message)
IO.puts("[x] '[#{topic}] #{message}'")
Connection.close(connection)
