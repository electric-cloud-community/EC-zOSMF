
// Was generated by REST Plugin Wizard
def procName = 'Console - Command response'
def stepName = 'console - command response'
procedure procName, description: 'Use this operation to get the response to a command that was issued asynchronously with the Issue Command service', {

    step stepName,
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('console - command response');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'

}
