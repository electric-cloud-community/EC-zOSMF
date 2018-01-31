procedure 'Jobs - List', description: 'You can use this operation to list the jobs for an owner, prefix, or job ID', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'jobs - list jobs',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('jobs - list jobs');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
