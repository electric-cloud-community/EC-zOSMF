
// Was generated by REST Plugin Wizard
def procName = 'Data Set - Read data'
def stepName = 'data set - retrieve the contents of a zOS data set or member'
procedure procName, description: 'You can use this operation to retrieve the contents of a sequential data set, or a member of a partitioned data set (PDS or PDSE). To retrieve the contents of an uncataloged data set, include the volume serial on the request', {

    step stepName,
        command: """
\$[/myProject/scripts/preamble]
use EC::RESTPlugin;
EC::RESTPlugin->new->run_step('data set - retrieve the contents of a zOS data set or member');
""",
        errorHandling: 'failProcedure',
        exclusiveMode: 'none',
        releaseMode: 'none',
        shell: 'ec-perl',
        timeLimitUnits: 'minutes'

}