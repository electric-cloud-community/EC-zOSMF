
// Was generated by REST Plugin Wizard
def procName = 'Jobs - List'
def stepName = 'jobs - list jobs'
procedure procName, description: 'You can use this operation to list the jobs for an owner, prefix, or job ID', {

    step stepName,
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

}