import
  std/macros,
  nclap,
  testutils

test "customizing help message":
  var parser = newParser("hacker looking echo\n")

  initParser(parser):
    Flag("-h", "--help", "shows this message", no_check=true)

    Flag("--text", description="text to print", required=false, holds_value=true)

  let args = parser.parse(@["--text", "this"])

  if ?args.help:
    parser.showHelp()
    quit(1)

  echo (args.text !! readAll(stdin))
