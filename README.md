# EC-zOSMF

This plugin allows to work with zOSMF REST API.


# Procedures

## System - Info

You can use this operation to retrieve information about z/OSMF on a particular z/OS system.

## Data Set - List

List the z/OS data sets on a system.

## Data Set - Read data

You can use this operation to retrieve the contents of a sequential data set, or a member of a partitioned data set (PDS or PDSE). To retrieve the contents of an uncataloged data set, include the volume serial on the request.

## Data Set - Write data

You can use this operation to write data to an existing sequential data set, or a member of a partitioned data set (PDS or PDSE). To write to an uncataloged data set, include a volume serial on the request.

## Data Set - Create

You can use this operation to create sequential and partitioned data sets on a z/OS system.

## Data Set - Delete

You can use this operation to delete sequential and partitioned data sets on a z/OS system.

## Jobs - Spool files list

You can use this operation to list the spool files for a batch job on z/OS.

## Jobs - Get spool file content

You can use this operation to list the spool files for a batch job on z/OS.

## Jobs - Submit a job

You can use this operation to submit a job to run on z/OS.

## Jobs - List

You can use this operation to list the jobs for an owner, prefix, or job ID.

## Jobs - Cancel and Purge

You can use this operation to cancel a job and purge its output.

## Jobs - Obtain status

You can use this operation to obtain the status of a batch job on z/OS

## Console - Issue Command

Use this operation to issue a command by using a system console.

## Console - Command response

Use this operation to get the response to a command that was issued asynchronously with the Issue Command service.

## Console - Unsolicited messages result

Use this operation to get the result for detecting a keyword in unsolicited messages after an Issue Command request. The command must have been issued with the unsol-key field.



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
