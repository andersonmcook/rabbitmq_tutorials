message =
  case System.argv() do
    [] -> "Hello World!"
    words -> Enum.join(words, " ")
  end

{:ok, connection} = AMQP.Connection.open()
{:ok, channel} = AMQP.Channel.open(connection)
# Declare the queue as durable
AMQP.Queue.declare(channel, "task_queue", durable: true)
# Publish persistent messages to the durable queue
AMQP.Basic.publish(channel, "", "task_queue", message, persistent: true)
AMQP.Connection.close(connection)
