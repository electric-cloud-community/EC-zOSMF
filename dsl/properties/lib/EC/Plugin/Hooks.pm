package EC::Plugin::Hooks;

use strict;
use warnings;
use MIME::Base64 qw(encode_base64);

use base qw(EC::Plugin::HooksCore EC::Plugin::Core);
use URI;
use URI::Escape;


use Data::Dumper;

=head1 SYNOPSYS

User-defined hooks

Available hooks types:

    before
    parameters
    request
    response
    parsed
    after

    ua - will be called when User Agent is created


    sub define_hooks {
        my ($self) = @_;

        $self->define_hook('my step', 'before', sub { ( my ($self) = @_; print "I'm before step my step" });
    }


=head1 SAMPLE


    sub define_hooks {
        my ($self) = @_;

        # step name is 'deploy artifact'
        # hook name is 'request'
        # This hook accepts HTTP::Request object
        $self->define_hook('deploy artifact', 'request', \&deploy_artifact);
    }

    sub deploy_artifact {
        my ($self, $request) = @_;

        # $self is a EC::Plugin::Hooks object. It has method ->plugin, which returns the EC::RESTPlugin object
        my $artifact_path = $self->plugin->parameters($self->plugin->current_step_name)->{filesystemArtifact};

        open my $fh, $artifact_path or die $!;
        binmode $fh;
        my $buffer;
        $self->plugin->logger->info("Writing artifact $artifact_path to the server");

        $request->content(sub {
            my $bytes_read = read($fh, $buffer, 1024);
            if ($bytes_read) {
                return $buffer;
            }
            else {
                return undef;
            }
        });
    }


=cut

# autogen end

sub define_hooks {
    my ($self) = @_;
    $self->define_hook('*', 'request', \&RUN_FOR_ALL_REQUESTS);

    $self->define_hook('data set - list zOS data sets on a system', 'parameters', \&check_list_zos_dataset_params);
    $self->define_hook('data set - list zOS data sets on a system', 'request', \&check_list_zos_dataset_request);
    #$self->define_hook('data set - create a sequential and partitioned data set', 'parameters', \&fix_create_dataset_params);
    $self->define_hook('data set - create a sequential and partitioned data set', 'request', \&check_create_dataset_request);

    $self->define_hook('data set - delete a sequential and partitioned data set', 'request', \&check_delete_dataset_request);
    $self->define_hook('data set - write data to a zos data set or member', 'request', \&write_dataset_hook_in_request);
    $self->define_hook('data set - retrieve the contents of a zOS data set or member', 'request', \&check_volser_member_in_request);
    $self->define_hook('data set - retrieve the contents of a zOS data set or member', 'content_callback', \&read_dataset_content_callback_request);
    $self->define_hook('data set - retrieve the contents of a zOS data set or member', 'after', \&read_dataset_after_request);

    

    $self->define_hook('jobs - submit a job', 'request', \&check_submit_job_request);
    $self->define_hook('jobs - spool files list', 'request', \&get_spool_files_request);

    $self->define_hook('jobs - get spool file content', 'request', \&get_spool_content_request);

    $self->define_hook('jobs - list jobs', 'parameters', \&list_jobs_params);

    $self->define_hook('jobs - cancel and purge', 'request', \&get_jobs_request);
    $self->define_hook('jobs - obtain status', 'request', \&get_jobs_request);
}


#defines protocol, host, port and additional URLPath for all requests
sub RUN_FOR_ALL_REQUESTS{
    my ($self, $request) = @_;
    my $path = $request->uri->path;
    my $opts = $self->get_config_values($self->plugin->{plugin_name}, $self->plugin->parameters->{'config'});
    if (exists($self->plugin->parameters->{'Content-Type'}) && $self->plugin->parameters->{'Content-Type'}){
         $request->header("Content-Type", $self->plugin->parameters->{'Content-Type'});
    }

    my $uri = $request->uri;
    $uri->scheme($opts->{'protocol'}); 
    $uri->host($opts->{'host'});
    $uri->port($opts->{'port'});
    $uri->path($opts->{'urlPath'}.$uri->path());
}



sub check_create_dataset_request{
    my ($self, $request) = @_;


}

sub get_spool_files_request{
    my ($self, $request) = @_;

    #checking by which way we get spool files
    if (exists($self->plugin->parameters->{'correlator'}) && $self->plugin->parameters->{'correlator'}){
        my $correlator = uri_escape($self->plugin->parameters->{'correlator'});
        print "Correlator: $correlator\n";
        my $path = $request->uri->path;
        my $new_path = $path."$correlator/files";
        $request->uri->path($new_path);
    }
    else{
        my ($jobname, $jobid) = ($self->plugin->parameters->{'jobname'}, $self->plugin->parameters->{'jobid'});
        my $path = $request->uri->path;
        my $new_path = $path."$jobname/$jobid/files";
        $request->uri->path($new_path);
    }
}

sub get_jobs_request{
    my ($self, $request) = @_;

    #checking by which way we get spool files
    if (exists($self->plugin->parameters->{'correlator'}) && $self->plugin->parameters->{'correlator'}){
        my $correlator = uri_escape($self->plugin->parameters->{'correlator'});
        my $path = $request->uri->path;
        my $new_path = $path."$correlator";
        $request->uri->path($new_path);
    }
    else{
        my ($jobname, $jobid) = ($self->plugin->parameters->{'jobname'}, $self->plugin->parameters->{'jobid'});
        my $path = $request->uri->path;
        my $new_path = $path."$jobname/$jobid";
        $request->uri->path($new_path);
    }
}

sub get_spool_content_request{
    my ($self, $request) = @_;

    $self->get_spool_files_request($request);

    if (exists($self->plugin->parameters->{'file'}) && $self->plugin->parameters->{'file'}){
        my $file_num = $self->plugin->parameters->{'file'};
        print "FileNum: $file_num\n";
        my $path = $request->uri->path;
        my $new_path = $path."/$file_num/records";
        $request->uri->path($new_path);
    }
    else{
        $self->bail_out("File is not passed");
    }
 
}



sub check_submit_job_request{
    my ($self, $request) = @_;

    #checking if we need to send to secondary JESB
    if (exists($self->plugin->parameters->{'JESB'}) && $self->plugin->parameters->{'JESB'}){
        my $jesb = $self->plugin->parameters->{'JESB'};
        my $path = $request->uri->path;
        my $new_path = $path."/-$jesb";
        $request->uri->path($new_path);
    }
    
    #checking the way to pass job
    if (exists($self->plugin->parameters->{'Content-Type'}) && $self->plugin->parameters->{'Content-Type'} eq 'application/json'){
        my $file = $self->plugin->parameters->{'file'};
        unless($file){
            $self->plugin->bail_out("File param is not set, please check procedure params");
        }
        $request->content("{\"file\" : \"$file\"}");
    }
    else{
        my $code = $self->plugin->parameters->{'code'};
        $request->content($code);
    }
}


sub check_delete_dataset_request{
    my ($self, $request) = @_;

}


sub read_dataset_content_callback_request {
    my ($self) = @_;
    # use Data::Dumper;
    # print(Dumper($self->plugin->parameters));
    # print "ddd  ".$self->plugin->parameters->{resultProperty};
    # if ($self->plugin->parameters($self->plugin->current_step_name)->{resultProperty} eq 'file'){

    my $file;
    print "outtype: ".$self->plugin->parameters($self->plugin->current_step_name)->{resultFormat};
    print "outfile: ".$self->plugin->parameters($self->plugin->current_step_name)->{resultPropertySheet};
    if ($self->plugin->parameters($self->plugin->current_step_name)->{resultFormat} eq 'file' && $self->plugin->parameters($self->plugin->current_step_name)->{resultPropertySheet}){
        $file = $self->plugin->parameters($self->plugin->current_step_name)->{resultPropertySheet};
    }
    else{
        #TO BE RE-DONE.. bad..
        $file = '/tmp/'.time.rand(1_000_000).'.out';
    }
    $self->{retrieve_data_filename} = $file;
    $self->plugin->parameters($self->plugin->current_step_name)->{resultPropertySheet};
    print "FILE: $file\n";
    $self->plugin->logger->debug("Streaming response to $file");

    $_[1] = sub {
        my ($chunk, $res) = @_;

        my $fh = $self->{retrieve_data_fh};
        unless($fh) {
            open $fh, '>' . $file or die "Cannot open file $file: $!";
            if (-B $chunk){
                binmode($fh);
            }
            $self->{retrieve_data_fh} = $fh;
            $self->plugin->logger->debug("Opened filehandle for writing");
        }
        print $fh $chunk;
    };
    #}
}

sub read_dataset_after_request {
    my ($self) = @_;

    my $fh = $self->{retrieve_data_fh};
    if ($fh) {
        $self->plugin->logger->debug("Closing filehandle");
        close $fh;
        if ($self->plugin->parameters($self->plugin->current_step_name)->{resultFormat} ne 'file'){
            open($fh, $self->{retrieve_data_filename}) || $self->plugin->bail_out("Something wrong on reading temp file");
            while(<$fh>){
                print $_;
            }
            close($fh);
            unlink($self->{retrieve_data_filename});
        }
    }
    $self->plugin->logger->info("Saved response under file ".$self->plugin->parameters($self->plugin->current_step_name)->{resultPropertySheet});
}



sub write_dataset_hook_in_request{
    my ($self, $request) = @_;
 
    #checking if we need to add -volser
    $self->check_volser_member_in_request($request);

    if (exists($self->plugin->parameters($self->plugin->current_step_name)->{'stored-data-file'}) && $self->plugin->parameters($self->plugin->current_step_name)->{'stored-data-file'}){
        my $data_file = $self->plugin->parameters($self->plugin->current_step_name)->{'stored-data-file'};
        if (-e $data_file){
            open my $fh, $data_file or die $!;
            print "YEP: $data_file\n";
            if (-B $data_file){
                binmode $fh;
            }
            my $buffer;
            $request->content(sub {
                my $bytes_read = read($fh, $buffer, 1024);
                if ($bytes_read) {
                    return $buffer;
                }
                else {
                    close $fh;
                    return undef;
                }
            });          
        }
        else{
            $self->bail_out("File $data_file doesn't exist");
        }
    }
    else{
        $request->content($self->plugin->parameters->{'stored-data'})
    }

}

sub check_volser_member_in_request{
    my ($self, $request) = @_;
    
    #checking if we need to add -volser
    if (exists($self->plugin->parameters->{'volser'}) && $self->plugin->parameters->{'volser'}){
        my $volser = $self->plugin->parameters->{'volser'};
        my @splitted_path = split /\//, $request->uri->path;
        my $new_path = join('/', @splitted_path[0,-2], '-'.$volser, $splitted_path[-1]);
        $request->uri->path($new_path);
    }

    #checking if we need to add member-name
    if (exists($self->plugin->parameters->{'member-name'}) && $self->plugin->parameters->{'member-name'}){
        my $member_name = $self->plugin->parameters->{'member-name'};
        my $path = $request->uri->path;
        my $new_path = $path."($member_name)";
        $request->uri->path($new_path);
    }

}

sub check_list_zos_dataset_params{
    my ($self, $parameters) = @_;
    #patching hardcoded param name
    $parameters->{'start'} = $parameters->{'start_num'};
    delete $parameters->{'start_num'};
}

sub list_jobs_params{
    my ($self, $parameters) = @_;
    #patching hardcoded param name
    $parameters->{'owner'} = $parameters->{'_owner'};
    delete $parameters->{'_owner'};
}

sub check_list_zos_dataset_request{
    my ($self, $request) = @_;
    # my $uri   = URI->new($request->uri());
    #->clone
    # my %query = $uri->query_form;
    
    # my %result_query;
    # foreach my $key(keys %query){
    #     if ($key eq 'start'){
    #         next;
    #     }
    #     $result_query{$key} = $query{$key};
    # }
    # $uri->query_form(\%result_query);
    # $request->uri($uri);

    if ($self->plugin->parameters->{'totalRows'}){
        my $x_imb_attr_header = $request->header("X-IBM-Attributes");
        unless ($x_imb_attr_header){
            $x_imb_attr_header = 'dsname';
        }
        $x_imb_attr_header .= ',total';
        $request->header("X-IBM-Attributes", $x_imb_attr_header);
    }
    

}

1;
