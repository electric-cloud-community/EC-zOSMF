procedure 'Jobs - Cancel and Purge', description: 'You can use this operation to cancel a job and purge its output', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'jobs - cancel and purge',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('jobs - cancel and purge');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
