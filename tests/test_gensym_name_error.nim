import
  std/options,

  nclap,
  testutils

const
  DEFAULT_WAIT_TIME = 10
  DEFAULT_MIN_TRIES = 10
  DEFAULT_MAX_TRIES = 10

test "initParser macro":
  proc main: Natural =
    var parser = newParser("hacker looking echo\n")

    initParser(parser):
      Flag("-h", "--help", "shows this message", no_check=true)

      UnnamedArgument("text")

      Flag("--stderr", description="prints to stderr instead of stdout by default")
      Flag("--stdin", description="take input from stdin", no_check=true)
      Flag("-w", "--wait-time", "number of milliseconds to wait between each try", default=some($DEFAULT_WAIT_TIME))
      Flag("-l", "--min-tries", "minimum number of guesses before printing the actual char", default=some($DEFAULT_MIN_TRIES))
      Flag("-h", "--max-tries", "maximum number of guesses before printing the actual char", default=some($DEFAULT_MAX_TRIES))
      Flag("-c", description="randomly selects only from chars in text")

    let args = parser.parse(@["-w=10", "-c", "text here"])

    check !args.text == "text here"
    #check (args.text !! readAll(stdin)) == "text here"
    check ?args.c
    check !args.wait_time == "10"

  discard main()
