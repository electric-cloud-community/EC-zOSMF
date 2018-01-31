procedure 'Jobs - Submit a job', description: 'You can use this operation to submit a job to run on z/OS', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'jobs - submit a job',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('jobs - submit a job');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]
}
