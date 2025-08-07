import
  nclap,
  testutils

test "customizing help message":
  var p = newParser("customizing help message", settings=HelpSettings(showhelp_depth: 3))

  initParser(p):
    Flag("-h", "--help", "shows this message", no_check=true)

    Command("add", ""):
      Command("task", "adds a task"):
        UnnamedArgument("name", "")
        UnnamedArgument("description", "")

      Command("project", "adds a project"):
        UnnamedArgument("name", "")
        UnnamedArgument("description", "")

    Command("remove", ""):
      Command("project", "removes a project"):
        UnnamedArgument("name")

      Command("task", "removes a project"):
        UnnamedArgument("name")
        Flag("-n", "--no-log", "does not log the deletion")
        Command("status"):
          Command("second-status"):
            UnnamedArgument("status-kind", "desc here")

    Command("list", ""):
      Flag("-a", "--all", "lists all tasks, even the hidden ones")

    Flag("-o", "--output", "outputs the content to a file", holds_value=true)
    Flag("-d", description="directory in which to do stuff")

  #p.showHelp()

  let args = p.parse(@["--help"])

  if ?args.help:
    p.showHelp()
    quit()

  echo args
