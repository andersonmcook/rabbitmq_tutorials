# RabbitmqTutorials

[Installation via Homebrew](https://www.rabbitmq.com/install-homebrew.html)

[Tutorial](https://www.rabbitmq.com/tutorials/tutorial-one-elixir.html)

Start
```sh
$ rabbitmq-server
```

Stop
```sh
$ rabbitmqctl stop
```


## Notes Dump

RabbitMQ

Tutorial 1. Hello World
RabbitMQ is a message broker, it accepts and forwards messages

Producing = sending messages
Producer = program that sends messages
Queue = stores messages, bound by host's memory and disk limits, a large message buffer
Consuming = receiving messages
Consumer = program that mostly waits to receive messages

Producers, Consumers, and Brokers don't have to reside on the same host

p -> [q] -> c

AMQP 0-9-1 is a protocol, and most likely the one we will use in production.

Sending
- [ ] Open a connection
- [ ] Open a channel in the connection
- [ ] Declare a queue in the channel
- [ ] Send a message to the queue
- [ ] Close the connection

Receiving
- [ ] Open a connection
- [ ] Open a channel in the connection
- [ ] Declare a queue in the channel
- [ ] Receive messages from the queue

`{:basic_deliver, payload, metadata}` is sent to the process

Tutorial 2. Work Queues
Create a work queue aka task queue to distribute time-consuming tasks among multiple workers.
Avoid doing resource-intensive tasks immediately and having to wait for it to complete.
Encapsulate a task as a message and send it to the queue.
Useful in web applications where it's impossible to handle a complex task during a short HTTP request window.
Easily parallelize work with multiple Workers.
By default, RabbitMQ will send each message to the next consumer, in sequence, round-robin.
There are no message timeouts, RMQ will redeliver messages when a consumer dies.
Manual message acknowledgments are turned on by default.
Must acknowledge to same channel or an exception is thrown.

Message/Queue Durability
Can declare a new queue as `durable: true`, but you can't redefine an existing non-durable queue as durable.
Can mark a message as `persistent: true` where the message is written to the disk.  The guarantee is not strong, however, as not every message is saved immediately.  If you need a stronger guarantee you can use "publisher confirms".

Fair Dispatch
Can use "Quality of Service" or `qos` to override round-robin dispatch and instead limit the work going to each Worker at a time.
The queue can fill up if all workers are busy.  You can add more workers or adjust message time-to-live (TTL).

Tutorial 3. Publish/Subscribe
Producers don't send directly to a queue.  They send them to an exchange.
An Exchange receives messages and pushes them to queues.
The rules for what the Exchange should do with the message are defined by the exchange type.
[ direct, topic, headers, fanout ]

Temporary Queues
Can declare a queue without a name and it will automatically get a randomly-generated name
Can declare a queue with `exclusive: true` which means the queue will be deleted on connection close.

Bindings
The relationship between exchange and queue is called a binding.
(The queue is interested in messages from this exchange)

Fanout
Routing key is ignored when publishing messages to fanout exchanges
"Mindless broadcasting"


Tutorial 4. Routing
Subscribe to a subset of messages

Bindings can take an extra `routing_key` parameter

Goal for this section is to filter messages based on severity. Write critical errors to disk, print all others to the console.

With a "direct" exchange, a message goes to the queues whose `routing_key` or "binding key" matches the `routing_key` of the message.  Messages that don't match will be discarded.  Can't do routing based on multiple criteria.

Can bind multiple queues with the same binding key

Tutorial 5. Topics
Subscribe to messages based on a different criteria.

Messages sent to a `topic` exchange can't have an arbitrary `routing_key`, it must be a list of words, delimited by dots.  255 byte limit. The `binding_key` must be in the same form.

For `binding_key`s:
	`*` can substitute exactly one word.
	`#` can substitute for zero or more words.
But they must still be separated by dots.

Can bind a queue with "#" and it will receive all messages.

Tutorial 6. Remote Procedure Call (RPC)
Rules of RPC:
	Make sure it's obvious which function call is local and which is remote
	Document your system. Make the dependencies between components clear
	Handle error cases. How should the client react when the RPC server is down for a long time?
	When in doubt, avoid RPC.  Use an asynchronous pipeline.  Instead of RPC-like blocking, results are asynchronously pushed to a next computation stage

Message Properties
`persistent` -> mark a message of persistent or transient
`content_type` -> describe the mime-type of the encoding, for JSON "application/json"
`reply_to` -> used to name a callback queue
`correlation_id` -> useful to correlate RPC responses with requests

How It Will Work
- [ ] When the Client starts up, it creates an anonymous exclusive callback queue
- [ ] For an RPC request, the Client sends a message with two properties `reply_to` which is set to the callback queue, and `correlation_id` which is set to a unique value for every request
- [ ] The request is sent o an `rpc_queue` queue
- [ ] The RPC worker (aka Server) is waiting for requests on that queue. When a request appears, it does the job and sends a message with the result back to the Client, using the queue from the `reply_to` field.
- [ ] The Client waits for data on the callback queue. When a message appears, it checks the `correlation_id` property. If it matches the value from the request it returns the response to the application
