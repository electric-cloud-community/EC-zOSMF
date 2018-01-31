procedure 'Data Set - List', description: 'List the z/OS data sets on a system', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'data set - list zOS data sets on a system',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('data set - list zOS data sets on a system');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
