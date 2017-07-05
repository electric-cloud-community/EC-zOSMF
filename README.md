# EC-zOSMF

This plugin allows to work with zOSMF REST API.


# Procedures

## Jobs - Submit a job

You can use this operation to submit a job to run on z/OS.

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
