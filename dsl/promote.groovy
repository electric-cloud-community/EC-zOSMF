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
  [procedureName: 'Jobs - Submit a job', stepName: 'jobs - submit a job'],
  [procedureName: 'Data Set - Create a sequential and partitioned data set', stepName: 'data set - create a sequential and partitioned data set'],
  [procedureName: 'Data Set - List zOS data sets on a system', stepName: 'data set - list zOS data sets on a system']
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
