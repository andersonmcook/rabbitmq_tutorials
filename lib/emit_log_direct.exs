alias AMQP.{
  Basic,
  Channel,
  Connection,
  Exchange
}

{:ok, connection} = Connection.open()
{:ok, channel} = Channel.open(connection)

{severities, message} =
  System.argv()
  |> OptionParser.parse!(strict: Keyword.new([:error, :info, :warning], &{&1, :boolean}))
  |> case do
    {[], message} -> {[info: true], message}
    params -> params
  end

message =
  case message do
    [] -> "Hello World"
    words -> Enum.join(words, " ")
  end

Exchange.declare(channel, "direct_logs", :direct)

for {severity, true} <- severities do
  Basic.publish(channel, "direct_logs", Atom.to_string(severity), message)
  IO.puts("[x] Sent '[#{severity}]  #{message}'")
end

Connection.close(connection)
