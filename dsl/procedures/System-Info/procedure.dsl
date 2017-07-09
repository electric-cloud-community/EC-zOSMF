
// Was generated by REST Plugin Wizard
def procName = 'System - Info'
def stepName = 'jobs - zosmf info'
procedure procName, description: 'You can use this operation to retrieve information about z/OSMF on a particular z/OS system', {

    step stepName,
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

}
