import groovy.transform.BaseScript
import com.electriccloud.commander.dsl.util.BasePlugin

//noinspection GroovyUnusedAssignment
@BaseScript BasePlugin baseScript

// Variables available for use in DSL code
def pluginName = args.pluginName
def upgradeAction = args.upgradeAction
def otherPluginName = args.otherPluginName

def pluginKey = getProject("/plugins/$pluginName/project").pluginKey
def pluginDir = getProperty("/projects/$pluginName/pluginDir").value

//List of procedure steps to which the plugin configuration credentials need to be attached
// ** steps with attached credentials
def stepsWithAttachedCredentials = [
  [procedureName: 'Data Set - List', stepName: 'data set - list zOS data sets on a system'],
  [procedureName: 'Jobs - Get spool file content', stepName: 'jobs - get spool file content'],
  [procedureName: 'System - Info', stepName: 'jobs - zosmf info'],
  [procedureName: 'Jobs - Spool files list', stepName: 'jobs - spool files list'],
  [procedureName: 'Jobs - Cancel and Purge', stepName: 'jobs - cancel and purge'],
  [procedureName: 'Jobs - Obtain status', stepName: 'jobs - obtain status'],
  [procedureName: 'Data Set - Read data', stepName: 'data set - retrieve the contents of a zOS data set or member'],
  [procedureName: 'Data Set - Delete', stepName: 'data set - delete a sequential and partitioned data set'],
  [procedureName: 'Data Set - Create', stepName: 'data set - create a sequential and partitioned data set'],
  [procedureName: 'Jobs - List', stepName: 'jobs - list jobs'],
  [procedureName: 'Jobs - Submit a job', stepName: 'jobs - submit a job'],
  [procedureName: 'Data Set - Write data', stepName: 'data set - write data to a zos data set or member']
]
// ** end steps with attached credentials       
project pluginName, {
    
    loadPluginProperties(pluginDir, pluginName)
    loadProcedures(pluginDir, pluginKey, pluginName, stepsWithAttachedCredentials)
    //plugin configuration metadata
    property 'ec_config', {
        form = '$[' + "/projects/${pluginName}/procedures/CreateConfiguration/ec_parameterForm]"
        property 'fields', {
            property 'desc', {
                property 'label', value: 'Description'
                property 'order', value: '1'
            }
        }
    }

}

// Copy existing plugin configurations from the previous
// version to this version. At the same time, also attach
// the credentials to the required plugin procedure steps.
upgrade(upgradeAction, pluginName, otherPluginName, stepsWithAttachedCredentials)
