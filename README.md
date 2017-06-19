# EC-zOSMF

This plugin allows to work with zOSMF REST API.


# Procedures

## Jobs - Submit a job

You can use this operation to submit a job to run on z/OS.

## Data Set - List zOS data sets on a system

List the z/OS data sets on a system.



# Building the plugin
1. Download or clone the EC-zOSMF repository.

    ```
    git clone https://github.com/electric-cloud/EC-zOSMF.git
    ```

5. Zip up the files to create the plugin zip file.

    ```
     cd EC-zOSMF
     zip -r EC-zOSMF.zip ./*
    ```

6. Import the plugin zip file into your ElectricFlow server and promote it.
