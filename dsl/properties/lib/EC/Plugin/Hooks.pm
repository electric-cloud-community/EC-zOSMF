package EC::Plugin::Hooks;

use strict;
use warnings;
use MIME::Base64 qw(encode_base64);

use base qw(EC::Plugin::HooksCore EC::Plugin::Core);
use URI;


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
    
    $self->define_hook('data set - write data to a zos data set or member', 'request', \&check_volser_member_in_request);
    $self->define_hook('data set - retrieve the contents of a zOS data set or member', 'request', \&check_volser_member_in_request);
    

}


#defines protocol, host, port and additional URLPath for all requests
sub RUN_FOR_ALL_REQUESTS{
    my ($self, $request) = @_;
    my $path = $request->uri->path;
    my $opts = $self->get_config_values($self->plugin->{plugin_name}, $self->plugin->parameters->{'config'});

    my $uri = $request->uri;
    $uri->scheme($opts->{'protocol'}); 
    $uri->host($opts->{'host'});
    $uri->port($opts->{'port'});
    $uri->path($opts->{'urlPath'}.$uri->path());
}



sub check_create_dataset_request{
    my ($self, $request) = @_;


}

sub check_delete_dataset_request{
    my ($self, $request) = @_;
    
    if (exists($self->plugin->parameters->{'volume'}) && $self->plugin->parameters->{'volume'}){
        my $volume = $self->plugin->parameters->{'volume'};
        my @splitted_path = split /\//, $request->uri->path;
        my $new_path = join('/', @splitted_path[0,-2], '-'.$volume, $splitted_path[-1]);
        $request->uri->path($new_path);
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
    print($self->plugin->parameters->{'member-name'});
    if (exists($self->plugin->parameters->{'member-name'}) && $self->plugin->parameters->{'member-name'}){
        print "changing path";
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
