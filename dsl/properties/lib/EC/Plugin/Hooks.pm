package EC::Plugin::Hooks;

use strict;
use warnings;
use MIME::Base64 qw(encode_base64);

use base qw(EC::Plugin::HooksCore);
use URI;

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
    $self->define_hook('data set - list zOS data sets on a system', 'parameters', \&check_list_zos_dataset_params);
    $self->define_hook('data set - list zOS data sets on a system', 'request', \&check_list_zos_dataset_request);

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
    # my %query = $uri->query_form;
    use Data::Dumper;
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
        $x_imb_attr_header .= ',total';
        $request->header("X-IBM-Attributes", $x_imb_attr_header);
    }
    print(Dumper($self->plugin->parameters));
    

}

1;
