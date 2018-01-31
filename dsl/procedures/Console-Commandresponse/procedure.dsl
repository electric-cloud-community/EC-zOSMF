procedure 'Console - Command response', description: 'Use this operation to get the response to a command that was issued asynchronously with the Issue Command service', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'console - command response',
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
    
    // [REST Plugin Wizard step ends]

}
