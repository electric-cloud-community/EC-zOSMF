procedure 'Data Set - Delete', description: 'You can use this operation to delete sequential and partitioned data sets on a z/OS system', { // [PROCEDURE]
    // [REST Plugin Wizard step]

    step 'data set - delete a sequential and partitioned data set',
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('data set - delete a sequential and partitioned data set');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'
    
    // [REST Plugin Wizard step ends]

}
