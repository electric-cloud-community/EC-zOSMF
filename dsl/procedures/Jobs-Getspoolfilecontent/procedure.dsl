procedure 'Jobs - Get spool file content', description: 'You can use this operation to list the spool files for a batch job on z/OS', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'jobs - get spool file content',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('jobs - get spool file content');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
