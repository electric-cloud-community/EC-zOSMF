procedure 'Console - Issue Command', description: 'Use this operation to issue a command by using a system console', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'console - issue command',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('console - issue command');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
