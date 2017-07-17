package EC::Plugin::ContentProcessor;

use strict;
use warnings;
use JSON;

use base qw(EC::Plugin::ContentProcessorCore);

package EC::Plugin::ContentProcessor;

use strict;
use warnings;
use JSON;
use Data::Dumper;

use base qw(EC::Plugin::ContentProcessorCore);

=head1 SYNOPSYS

Here one can define custom processors for request & response. E.g., request
is not a plain JSON object but a file, or response does not contain JSON.

By default we assume that request body should be in JSON format and
response returns JSON as well.


Two processors can be defined:
    serialize_body - which will be used to serialize request body
    parse_response - which will be used to parse the content of the response

Code may look like the following:

    use constant {
        RETRIEVE_ARTIFACT => 'retrieve artifact',
        DEPLOY_ARTIFACT => 'deploy artifact',
    };


    sub define_processors {
        my ($self) = @_;

        $self->define_processor(DEPLOY_ARTIFACT, 'serialize_body', \&deploy_artifact);
        $self->define_processor(RETRIEVE_ARTIFACT, 'parse_response', \&download_artifact);
    }

    sub deploy_artifact {
        my ($self, $body) = @_;

        my $path = $body->{filesystemArtifact};

        open my $fh, $path or die "Cannot open $path: $!";
        binmode $fh;

        my $data = '';
        my $buffer;
        while( my $bytes_read = read($fh, $buffer, 1024)) {
            $data .= $buffer;
        }

        close $fh;


        # Here we return file content instead of JSON object
        return $data;
    }

    sub download_artifact {
        my ($self, $response) = @_;

        my $directory = $self->plugin->parameters(RETRIEVE_ARTIFACT)->{destination};

        $self->plugin->logger->debug("Destintion is $directory");
        my $filename = $response->header('x-artifactory-filename');


        my $dest_filename = $directory ? "$directory/$filename" : $filename;

        # And here we write a file instead of parsing response body as JSON

        open my $fh, ">$dest_filename" or die "Cannot open $dest_filename: $!";
        print $fh $response->content;
        close $fh;

        $self->plugin->logger->info("Artifact $dest_filename is saved");
        $self->plugin->set_summary("Artifact $dest_filename is saved");
    }


=cut


# autogen code ends here

sub define_processors {
    my $self = shift;

    $self->define_processor('jobs - zosmf info', 'parse_response', sub{ my ($self, $response) = @_; return decode_json($response->content);});
    $self->define_processor('jobs - submit a job', 'serialize_body', sub{ my ($self, $body) = @_; return $body->{ (keys %$body)[0] };} );
    $self->define_processor('jobs - spool files list', 'parse_response', \&spool_files_list_response);
    $self->define_processor('jobs - list jobs', 'parse_response', sub{my ($self, $response) = @_; $self->convert_arr_to_hash_by_key($response, 'jobid');});


    $self->define_processor('data set - write data to a zos data set or member', 'serialize_body', sub{ my ($self, $body) = @_; return $body->{'stored-data'};} );
    $self->define_processor('data set - retrieve the contents of a zOS data set or member', 'parse_response', \&save_data_into_file);
    $self->define_processor('jobs - get spool file content', 'parse_response', \&save_data_into_file );
}

sub spool_files_list_response {
    my ($self, $response) = @_;

    my $content = $response->content;
    my @files;
    my $res = {};

    my $data = decode_json($response->content);
    $self->plugin->logger->info("zOSMF response:", JSON->new->pretty->utf8->encode($data));
    foreach my $item (@$data){
        push @files, $item->{'id'};
        foreach my $key (qw(job-correlator subsystem stepname jobid jobname)){
            $res->{$key} = $item->{$key} if !($res->{$key});
        }
    }
    $res->{'files'} = join(',',@files);
    return $res;
}

sub convert_arr_to_hash_by_key{
    my ($self, $response, $index_key) = @_;

    my $res = {};

    my $data = decode_json($response->content);
    #$self->plugin->logger->info("zOSMF response:", JSON->new->pretty->utf8->encode($data));
    foreach my $item (@{ $data }){
        my $id = $item->{"$index_key"};
        $res->{"$id"} = $item;
    }
    return $res;
}

#deprecated for now
sub save_data_into_file{
    my ($self, $response, $step_name) = @_;
    my $result_format = $self->plugin->parameters($step_name)->{resultFormat};
    #to be updated
    if ($result_format ne 'file'){
        my $data = $response->content; 
        print($data); 
        #$data =~ s/'/\\'/ig; 
        my $res = {}; 
        $res->{'data'} = $data; 
        return $res;
    }
    else{
        my $res = {};
        $res->{'data'}  = $response->content;
        return $res;
    }
}



1;
