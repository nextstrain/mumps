"""
This part of the workflow deals with configuration.

OUTPUTS:

    results/run_config.yaml
"""
def main():
    write_subsample_config()
    write_config("results/run_config.yaml")


def conditional(option, argument):
    """Used for config-defined arguments whose presence necessitates a command-line option
    (e.g. --foo) prepended and whose absence should result in no option/arguments in the CLI command.
    *argument* can be None, in which case an empty string is returned (i.e. "don't pass anything
    to the CLI"), or a *list* or *string* or *number* in which case a flat list of options/args is returned,
    or *True* in which case a list of a single element (the option) is returned.
    Any other argument type is a WorkflowError
    """
    if argument is None:
        return ""
    if argument is True: # must come before `isinstance(argument, int)` as bool is a subclass of int
        return [option]
    if isinstance(argument, list):
        return [option, *argument]
    if isinstance(argument, int) or isinstance(argument, float) or isinstance(argument, str):
        return [option, argument]
    raise WorkflowError(f"Workflow function conditional() received an argument value of unexpected type: {type(argument).__name__}")


def write_subsample_config():
    for build in config["builds"]:
        if "custom_subsample" in config:
            section = ["custom_subsample", build]
        else:
            section = ["subsample", build]
        write_config(f"results/{build}/subsample_config.yaml", section=section)


try:
    main()
except InvalidConfigError as e:
    print(f"ERROR: {e}", file=sys.stderr)
    exit(1)
