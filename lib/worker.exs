defmodule Worker do
  def wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        IO.puts("Received #{payload}")

        payload
        |> Kernel.to_charlist()
        # count all '.' in the char list by testing if each
        # character (codepoint) equals the codepoint of '.'
        |> Enum.count(&(&1 == ?.))
        |> :timer.seconds()
        |> :timer.sleep()

        IO.puts("Done")
        # Ack after work is done
        AMQP.Basic.ack(channel, meta.delivery_tag)
        wait_for_messages(channel)
    end
  end
end

{:ok, connection} = AMQP.Connection.open()
{:ok, channel} = AMQP.Channel.open(connection)
# Idempotent
# Can't redefine a non-durable queue into a durable one
AMQP.Queue.declare(channel, "task_queue", durable: true)
# Make sure a Worker doesn't have more than one message waiting
# To make sure round robin isn't sending easy work to one worker while building up hard work on another
AMQP.Basic.qos(channel, prefetch_count: 1)
# 3rd argument is the consumer process, defaults to self()
# AMQP.Basic.consume(channel, "task_queue", nil, no_ack: true)
AMQP.Basic.consume(channel, "task_queue")
Worker.wait_for_messages(channel)
