import std/[
  strformat,
  sugar,
  options,
  sequtils,
  strutils
]

const
  FLAG_HOLDS_VALUE_DEFAULT* = false
  FLAG_REQUIRED_DEFAULT* = false
  COMMAND_REQUIRED_DEFAULT* = true
  UNNAMED_ARGUMENT_PREFIX* = "$"
  HOLDS_VALUE_DEFAULT* = false
  NO_CHECK_DEFAULT* = false

  DEFAULT_TABSTRING = "  "
  DEFAULT_PREFIX_PRETAB = ""
  DEFAULT_PREFIX_POSTTAB_FIRST = ""
  DEFAULT_PREFIX_POSTTAB = ""
  DEFAULT_PREFIX_POSTTAB_LAST = ""
  DEFAULT_SURROUND_LEFT_REQUIRED = "<"
  DEFAULT_SURROUND_RIGHT_REQUIRED = ">"
  DEFAULT_SURROUND_LEFT_OPTIONAL = "["
  DEFAULT_SURROUND_RIGHT_OPTIONAL = "]"
  DEFAULT_SEPARATOR = "|"
  DEFAULT_SHOWHELP_DEPTH = 1

  #DEFAULT_SHOWHELP_SETTINGS* = (
  #  tabstring: "  ",
  #  prefix_pretab: "",
  #  prefix_posttab_first: "",
  #  prefix_posttab: "",
  #  prefix_posttab_last: "",
  #  surround_left_required: "(",
  #  surround_right_required: ")",
  #  surround_left_optional: "[",
  #  surround_right_optional: "]",
  #  separator: "|",
  #  showhelp_depth: SHOWHELP_DEPTH_DEFAULT
  #)

type
  HelpSettings* = object
    tabstring*: string = DEFAULT_TABSTRING
    prefix_pretab*: string = DEFAULT_PREFIX_PRETAB
    prefix_posttab_first*: string = DEFAULT_PREFIX_POSTTAB_FIRST
    prefix_posttab*: string = DEFAULT_PREFIX_POSTTAB
    prefix_posttab_last*: string = DEFAULT_PREFIX_POSTTAB_LAST
    surround_left_required*: string = DEFAULT_SURROUND_LEFT_REQUIRED
    surround_right_required*: string = DEFAULT_SURROUND_RIGHT_REQUIRED
    surround_left_optional*: string = DEFAULT_SURROUND_LEFT_OPTIONAL
    surround_right_optional*: string = DEFAULT_SURROUND_RIGHT_OPTIONAL
    separator*: string = DEFAULT_SEPARATOR
    showhelp_depth*: int = DEFAULT_SHOWHELP_DEPTH

  ArgumentType* = enum
    Command
    Flag
    UnnamedArgument

  Argument* = ref object
    description*: string
    required*: bool
    holds_value*: bool
    default*: Option[string]

    case kind*: ArgumentType
      of Flag:
        short*: string
        long*: string
        no_check*: bool  # NOTE: if set and flag is registered in argv, discards required cliargs check

      of Command:
        name*: string
        subcommands*: seq[Argument]

      of UnnamedArgument:
        ua_name*: string


func newFlag*(
  short: string,
  long: string = short,
  description: string = "",
  holds_value: bool = FLAG_HOLDS_VALUE_DEFAULT,
  required: bool = FLAG_REQUIRED_DEFAULT,
  no_check: bool = NO_CHECK_DEFAULT,
  default: Option[string] = none[string]()
): Argument =
  Argument(
    kind: Flag,
    short: short,
    long: long,
    description: description,
    holds_value: holds_value,
    required: required,
    no_check: no_check,
    default: default
  )

func newCommand*(
  name: string,
  subcommands: seq[Argument] = @[],
  description: string = "",
  required: bool = COMMAND_REQUIRED_DEFAULT,
  #holds_value: bool = HOLDS_VALUE_DEFAULT,
  #default: Option[string] = none[string]()
): Argument =
  Argument(
    kind: Command,
    name: name,
    subcommands: subcommands,
    description: description,
    required: required,
    holds_value: false,
    default: none[string]()
  )


func newUnnamedArgument*(
  name: string,
  description: string = "",
  default: Option[string] = none[string]()
): Argument =
  Argument(
    kind: UnnamedArgument,
    ua_name: name,
    holds_value: true,
    description: description,
    required: true,
    default: default
  )


func `$`*(argument: Argument): string =
  case argument.kind
    of Flag:
      let
        s = argument.short
        l = argument.long
        h = argument.holds_value
        desc = argument.description
        def = argument.default
        r = argument.required

      &"Flag(short: \"{s}\", long: \"{l}\", holds_value: {h}, description: \"{desc}\", required: {r}, default: {def})"

    of Command:
      let
        n = argument.name
        s = argument.subcommands
        desc = argument.description
        def = argument.default
        r = argument.required
        h = argument.holds_value

      &"Command(name: \"{n}\", subcommands: {s}, description: \"{desc}\", required: {r}, has_content: {h}, default: {def})"

    of UnnamedArgument:
      #&"[WARNING]: not implemented yet"
      let
        n = argument.ua_name
        d = argument.description

      &"UnnamedArgument(name: \"{n}\", description: \"{d}\")"


func getFlags*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Flag)

func getCommands*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == Command)

func getUnnamedArguments*(arguments: seq[Argument]): seq[Argument] =
  arguments.filter(arg => arg.kind == UnnamedArgument)


func argument_to_string_without_description*(
  argument: Argument,
  settings: HelpSettings = HelpSettings(),
  #depth: int = 0,
  #is_first: bool = true,
  #is_last: bool = false
): string =
  let
    #tabstring = settings.tabstring
    prefix_pretab = settings.prefix_pretab
    #prefix_posttab_first = settings.prefix_posttab_first
    #prefix_posttab = settings.prefix_posttab
    #prefix_posttab_last = settings.prefix_posttab_last
    surround_left_required = settings.surround_left_required
    surround_right_required = settings.surround_right_required
    surround_left_optional = settings.surround_left_optional
    surround_right_optional = settings.surround_right_optional
    separator = settings.separator
    #showhelp_depth = settings.showhelp_depth

    #tabrepeat = tabstring.repeat(depth)
    tabrepeat = ""
    #posttab = (
    #  if is_last: prefix_posttab_last
    #  elif is_first: prefix_posttab_first
    #  else: prefix_posttab
    #)
    posttab = ""

  let
    surround_left = (if argument.required: surround_left_required else: surround_left_optional)
    surround_right = (if argument.required: surround_right_required else: surround_right_optional)

  case argument.kind:
    of Flag:
      let
        usage = (
          if argument.short == argument.long: &"{surround_left}{argument.short}{surround_right}"
          else: &"{surround_left}{argument.short}{separator}{argument.long}{surround_right}"
        )
        #desc = &"{argument.description}"

      # NOTE: no subcommands to a flag, it is the first but more importantly the last
      &"{prefix_pretab}{tabrepeat}{posttab}{usage}"

    of Command:
      var res = ""

      let
        #usage = &"{surround_left}{argument.name}{surround_right}"
        usage = &"{argument.name}"
        #desc = &"{argument.description}"

      res &= &"{prefix_pretab}{tabrepeat}{posttab}{usage}"

      #for i in 0..<len(argument.subcommands):
      #  let
      #    subargument = argument.subcommands[i]
      #    is_last_argument = (i == len(argument.subcommands)-1)
      #
      #  res &= "\n" & subargument.helpToStringAux(settings=settings, depth=depth+1, is_last=is_last_argument)

      res

    of UnnamedArgument:
      &"{tabrepeat}{surround_left_required}{argument.ua_name}{surround_right_required}"
      #&"[WARNING]: still not implemented"


func argument_to_string_without_description_maxlength*(
  arguments: seq[Argument],
  indent_desc: int,
  tabstring_len: int,
  maxdepth: int = 0,
  depth: int = 0
): int =
  if depth > maxdepth:
    return -1

  var res = 0

  for argument in arguments:
    let argname =
      case argument.kind:
        of Flag: &"{argument.short}|{argument.long}"
        of UnnamedArgument: argument.ua_name
        of Command: argument.name



    let
      tmp = argument_to_string_without_description(argument).len - (
        if argument.description == "": indent_desc
        else: 0
      )
      tmp_rec = (
        if argument.kind == Command and depth < maxdepth:
          let k = argument_to_string_without_description_maxlength(
            argument.subcommands,
            tabstring_len,
            indent_desc,
            maxdepth,
            depth+1
          )

          if k == -1: -1
          else: k + (tabstring_len * depth+1)
        else: -1
      )

    res = max(res, max(tmp, tmp_rec))

  res


#func helpToString*(
#  argument: Argument,
#  settings: HelpSettings = DEFAULT_SHOWHELP_SETTINGS,
#  is_first: bool = true,
#  is_last: bool = false
#): string =
#  helpToStringAux(argument, settings, 0, is_first, is_last)


#func argument_to_string_without_description*(argument: Argument): string =
#  assert false, "# TODO: finish adding customization to display with '(', '[', '#' or whatever HelpSettings is defined"
#
#  return case argument.kind:
#    of Command: &"{argument.name}"
#    of Flag: &"{argument.short}|{argument.long}"
#    of UnnamedArgument: &"{argument.ua_name}"
