send = fn ->
  Code.eval_file("./lib/send.exs")
end

receive = fn ->
  Code.eval_file("./lib/receive.exs")
end
