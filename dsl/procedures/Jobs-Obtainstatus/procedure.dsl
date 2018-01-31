procedure 'Jobs - Obtain status', description: 'You can use this operation to obtain the status of a batch job on z/OS', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'jobs - obtain status',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('jobs - obtain status');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
