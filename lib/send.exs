{:ok, connection} = AMQP.Connection.open()
{:ok, channel} = AMQP.Channel.open(connection)
# Idempotent
AMQP.Queue.declare(channel, "hello")
# "" is a default exchange
AMQP.Basic.publish(channel, "", "hello", "Hello World!")
AMQP.Connection.close(connection)
