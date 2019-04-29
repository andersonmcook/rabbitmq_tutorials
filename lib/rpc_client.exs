defmodule FibonacciRPCClient do
  alias AMQP.{
    Basic,
    Channel,
    Connection,
    Queue
  }

  def wait_for_messages(_channel, correlation_id) do
    receive do
      {:basic_deliver, payload, %{correlation_id: ^correlation_id}} ->
        # {n, _} = Integer.parse(payload)
        payload
        |> Integer.parse()
        |> elem(0)
    end
  end

  def call(n) do
    {:ok, connection} = Connection.open()
    {:ok, channel} = Channel.open(connection)
    {:ok, %{queue: queue_name}} = Queue.declare(channel, "", exclusive: true)
    Basic.consume(channel, queue_name, nil, no_ack: true)

    correlation_id =
      :erlang.unique_integer()
      |> Integer.to_string()
      |> Base.encode64()

    Basic.publish(channel, "", "rpc_queue", Integer.to_string(n),
      reply_to: queue_name,
      correlation_id: correlation_id
    )

    wait_for_messages(channel, correlation_id)
  end
end

num =
  case System.argv() do
    [] ->
      30

    param ->
      param
      |> Enum.join(" ")
      |> Integer.parse()
      |> elem(0)
  end

IO.puts("[x] Requesting fib(#{num})")
response = FibonacciRPCClient.call(num)
IO.puts("[.] Got #{response}")
