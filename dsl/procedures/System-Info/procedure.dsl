procedure 'System - Info', description: 'You can use this operation to retrieve information about z/OSMF on a particular z/OS system', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'jobs - zosmf info',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('jobs - zosmf info');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
