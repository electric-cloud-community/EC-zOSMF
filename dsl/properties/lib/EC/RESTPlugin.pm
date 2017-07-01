package EC::RESTPlugin;

use strict;
use warnings;

use base qw(EC::Plugin::Core);
use EC::Plugin::Hooks;
use EC::Plugin::Validators;
use EC::Plugin::ContentProcessor;
use EC::Plugin::Refiners;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use MIME::Base64 qw(encode_base64);
use URI;
use Carp qw(confess);

use constant {
    RESULT_PROPERTY_SHEET_FIELD => 'resultPropertySheet'
};


=head2 after_init_hook

Debug level - we are reading property /projects/EC-PluginName-1.0.0/debugLevel.
If this property exists, it will set the debug level. Otherwize debug level will be 0, which is info.

=cut

sub after_init_hook {
    my ($self, %params) = @_;

    $self->{plugin_name} = '@PLUGIN_NAME@';
    $self->{plugin_key} = '@PLUGIN_KEY@';
    my $debug_level = 0;
    my $proxy;

    if ($self->{plugin_key}) {
        eval {
            $debug_level = $self->ec()->getProperty(
                "/plugins/$self->{plugin_key}/project/debugLevel"
            )->findvalue('//value')->string_value();
        };

        eval {
            $proxy = $self->ec->getProperty(
                "/plugins/$self->{plugin_key}/project/proxy"
            )->findvalue('//value')->string_value;
        };
    }
    if ($debug_level) {
        $self->debug_level($debug_level);
        $self->logger->debug("Debug enabled for $self->{plugin_key}");
    }

    else {
        $self->debug_level(0);
    }

    if ($proxy) {
        $self->{proxy} = $proxy;
        $self->logger->info("Proxy enabled: $proxy");
    }

}


sub hooks {
    my ($self) = @_;
    unless($self->{hooks}) {
        $self->{hooks} = EC::Plugin::Hooks->new($self);
    }
    return $self->{hooks};
}


sub validators {
    my ($self) = @_;

    unless($self->{validators}) {
        $self->{validators} = EC::Plugin::Validators->new;
    }
    return $self->{validators};
}

sub refiners {
    my ($self) = @_;

    unless($self->{refiners}) {
        $self->{refiners} = EC::Plugin::Refiners->new;
    }
    return $self->{refiners};
}

sub content_processor {
    my ($self) = @_;

    unless($self->{content_processor}) {
        $self->{content_processor} = EC::Plugin::ContentProcessor->new(plugin => $self);
    }
    return $self->{content_processor};
}

sub config {
    my ($self) = @_;

    unless($self->{steps_config}) {
        my $value = $self->ec->getProperty('/myProject/properties/pluginConfig')->findvalue('//value')->string_value;
        my $config = decode_json($value);
        $self->{steps_config} = $config;
    }
    return $self->{steps_config};
}

sub current_step_name {
    my ($self, $step_name) = @_;

    if ($step_name) {
        $self->{current_step_name} = $step_name;
    }
    else {
        return $self->{current_step_name};
    }
}

sub generate_step_request {
    my ($self, $step_name, $config, $parameters) = @_;

    my $endpoint = $self->config->{$step_name}->{endpoint};

    my $key = qr/[\w\-.?!]+/;
    # replace placeholders
    my $config_values_replacer = sub {
        my ($value) = @_;
        return $config->{$value} || '';
    };
    $endpoint =~ s/#\{\{($key)\}\}/$config_values_replacer->($1)/ge;

    my $parameters_replacer = sub {
        my ($value) = @_;
        return $parameters->{$value} || '';
    };

    $endpoint =~ s/#\{($key)\}/$parameters_replacer->($1)/ge;

    my $uri = URI->new($endpoint);
    my %query = ();
    my %body = ();
    my %headers = ();

    for my $field ( @{$self->config->{$step_name}->{parameters}}) {
        my $name = $field->{property};
        my $value = $parameters->{$name};
        next unless $field->{in};

        if ($field->{in} eq 'query') {
            if (defined $value) {
                $query{$name} = $value;
            }
        }
        elsif ($field->{in} eq 'body') {
            if (defined $value) {
                $body{$name} = $value;
            }
        }
        elsif ($field->{in} eq 'header') {
            if (defined $value) {
                $headers{$name} = $value;
            }
        }
    }

    $uri->query_form(%query);
    $self->logger->debug(\%body);

    my $method = $self->config->{$step_name}->{method};
    my $payload;
    if (%body || $method =~ /PATCH|PUT|POST/) {
        $payload = $self->content_processor->run_serialize_body($step_name, \%body);
        $self->logger->info("Payload size: " . length($payload));
    }

    $self->logger->debug("Endpoint: $uri");


    my $request = HTTP::Request->new($method, $uri);

    if ($self->config->{$step_name}->{basicAuth} && $self->config->{$step_name}->{basicAuth} eq 'true') {
        $self->logger->debug('Adding basic auth');

        my $username = $config->{userName};
        my $password = $config->{password};

        unless ($self->config->{$step_name}->{canSkipAuth}) {
            unless ($username){
                return $self->bail_out('No username found in configuration');
            }
            unless($password) {
                return $self->bail_out('No password found in configuration');
            }
        }
        $request->authorization_basic($username, $password);
    }

    if (%headers) {
        for (keys %headers) {
            $request->header($_ => $headers{$_});
        }
    }

    $request->content($payload) if $payload;
    my $content_type = $self->config->{$step_name}->{contentType};

    if ( $self->config->{$step_name}->{bodyContentType} &&
            $self->config->{$step_name}->{bodyContentType} eq 'json') {
        $content_type ||= 'application/json';
    }
    if ($content_type) {
        $request->header('Content-Type' => $content_type);
    }

    return $request;
}

sub request {
    my ($self, $step_name, $request) = @_;

    my $ua = LWP::UserAgent->new;
    $self->hooks->ua_hook($step_name, $ua);
    my $callback = undef;

    $self->hooks->content_callback_hook($step_name, $callback);
    $self->logger->trace('Content callback', $callback);
    # my @request_parameters = $self->hooks->request_parameters_hook($step_name, $request);

    if ($self->{proxy}) {
        $ua->proxy(['http', 'https'] => $self->{proxy});
        $self->logger->info("Proxy set for request");
        $ua->requests_redirectable([qw/GET POST PUT PATCH GET HEAD OPTIONS DELETE/]);
    }
    my $response = $ua->request($request, $callback);
    return $response;
}

sub run_step {
    my ($self, $step_name) = @_;

    eval {
        my $plugin_name = $self->{plugin_name};
        my $summary = qq{
Plugin: $plugin_name
Running step: $step_name
};
        $self->logger->info($summary);
        $self->current_step_name($step_name);
        die 'No step name' unless $step_name;
        $self->logger->debug("Running step named $step_name");
        $self->hooks->define_hooks;
        $self->content_processor->define_processors;

        $self->hooks->before_hook($step_name);
        my $parameters = $self->parameters($step_name);

        $self->logger->debug('Parameters', $parameters);
        $self->hooks->parameters_hook($step_name, $parameters);

        my $config = {};
        if ($self->config->{$step_name}->{hasConfig}) {
            $config = $self->get_config_values($parameters->{config});
            $self->logger->debug('Config', $config);
        }

        my $request = $self->generate_step_request($step_name, $config, $parameters);
        $self->hooks->request_hook($step_name, $request); # request can be altered by the hook
        $self->logger->info("Going to run request");
        $self->logger->trace("Request", $request);
        my $response = $self->request($step_name, $request);
        $self->hooks->response_hook($step_name, $response);

        unless($response->is_success) {
            $self->logger->info("Response", $response->content);
            my $message = 'Request failed: ' . $response->status_line;
            return $self->bail_out($message);
        }
        else {
            $self->logger->info('Request succeeded');
        }
        my $parsed = $self->parse_response($step_name, $response);

        $self->hooks->parsed_hook($step_name, $parsed);

        $self->save_parsed_data($step_name, $parsed);

        $self->hooks->after_hook($step_name);

        1;
    } or do {
        my $error = $@;
        $self->ec->setProperty('/myCall/summary', $error);
        die $error;
    };
}

sub parse_response {
    my ($self, $step_name, $response) = @_;

    return $self->content_processor->run_parse_response($step_name, $response);
}

sub save_parsed_data {
    my ($self, $step_name, $parsed_data) = @_;

    my $config = $self->config->{$step_name}->{resultProperty};
    return unless $config && $config->{show};

    my $property_name = $self->parameters($step_name)->{+RESULT_PROPERTY_SHEET_FIELD};

    my $formats = $config->{format};
    my $selected_format;

    if (scalar @$formats > 0) {
        $selected_format = $self->parameters($step_name)->{resultFormat}; # TODO constant
    }
    else {
        $selected_format = $formats->[0];
    }

    unless($selected_format) {
        return $self->bail_out('No format has beed selected');
    }

    unless($parsed_data) {
        $self->logger->info("Nothing to save");
        return;
    }

    $self->logger->info("Got data", JSON->new->pretty->encode($parsed_data));

    if ($selected_format eq 'propertySheet') {
        my $flat_map = _flatten_map($parsed_data, $property_name);

        for my $key (sort keys %$flat_map) {
            $self->ec->setProperty($key, $flat_map->{$key});
            $self->logger->info("Saved $key -> $flat_map->{$key}");
        }
    }
    elsif ($selected_format eq 'json') {
        my $json = encode_json($parsed_data);
        $self->ec->setProperty($property_name, $json);
        $self->logger->info("Saved answer under $property_name");
    }
    else {
        $self->bail_out("Cannot process format $selected_format: not implemented");
    }
}

sub parameters {
    my ($self, $step_name) = @_;

    $step_name ||= $self->current_step_name;
    confess 'No step name' unless $step_name;

    unless($self->{parameters}->{$step_name}) {
        $self->{parameters}->{$step_name} = $self->grab_parameters($step_name);
    }
    return $self->{parameters}->{$step_name};
}

sub show_result_property {
    my ($self, $step_name) = @_;

    return $self->config->{$step_name}->{resultProperty} && $self->config->{$step_name}->{resultProperty}->{show};
}

sub result_formats {
    my ($self, $step_name) = @_;

    return $self->config->{$step_name}->{resultProperty}->{format} || [];
}

sub grab_parameters {
    my ($self, $step_name) = @_;

    my $fields = $self->config->{$step_name}->{fields};
    if ($self->config->{$step_name}->{hasConfig}) {
        push @$fields, 'config';
    }
    if ($self->show_result_property($step_name)) {
        push @$fields, RESULT_PROPERTY_SHEET_FIELD;
    }
    if (scalar @{$self->result_formats($step_name)} > 1) {
        push @$fields, 'resultFormat';
    }
    unless ($fields && scalar @$fields) {
        die "No fields defined for step $step_name";
    }
    my $parameters = $self->get_params_as_hashref(@$fields);
    $self->validate($step_name, $parameters);
    $parameters = $self->refine($step_name, $parameters);
    return $parameters;
}

sub refine {
    my ($self, $step_name, $parameters) = @_;

    for my $name (keys %$parameters) {
        my $refine = $self->get_refiner($step_name, $name);
        if ($refine) {
            $parameters->{$name} = $self->refiners->$refine($parameters->{$name});
        }
    }
    return $parameters;
}

sub get_refiner {
    my ($self, $step_name, $param_name) = @_;

    my ($field) = grep  {$_->{property} eq $param_name} @{$self->config->{$step_name}->{parameters}};
    return $field->{refiner};
}

sub validate {
    my ($self, $step_name, $parameters) = @_;

    my @messages = ();
    for my $name (keys %$parameters) {
        my $value = $parameters->{$name};
        my $validators = $self->get_validators($step_name, $name);
        for my $validator_name (@$validators) {
            my $error  = $self->validators->$validator_name($value);
            if ($error) {
                push @messages, $error;
            }
        }
    }
    if ( scalar @messages ) {
        return $self->bail_out("Validation errors: " . join("\n", @messages));
    }
}

sub get_validators {
    my ($self, $step_name, $param_name) = @_;

    my ($field) = grep  {$_->{property} eq $param_name} @{$self->config->{$step_name}->{parameters}};
    my $validators = $field->{validators};

    return [] unless $validators;
    $validators = [$validators] unless ref $validators eq 'ARRAY';

    return $validators;
}

sub get_config_values {
    my ($self, $config_name) = @_;

    die 'No config name' unless $config_name;
    my $plugin_project_name = '@PLUGIN_KEY@-@PLUGIN_VERSION@';
    my $config_property_sheet = "/projects/$plugin_project_name/ec_plugin_cfgs/$config_name";
    my $property_sheet_id = $self->ec->getProperty($config_property_sheet)->findvalue('//propertySheetId')->string_value;

    my $properties = $self->ec->getProperties({propertySheetId => $property_sheet_id});

    my $retval = {};
    for my $node ( $properties->findnodes('//property')) {
        my $value = $node->findvalue('value')->string_value;
        my $name = $node->findvalue('propertyName')->string_value;
        $retval->{$name} = $value;

        if ($name =~ /credential/) {
            my $credentials = $self->ec->getFullCredential($config_name);
            my $user_name = $credentials->findvalue('//userName')->string_value;
            my $password = $credentials->findvalue('//password')->string_value;
            $retval->{userName} = $user_name;
            $retval->{password} = $password;
        }
    }

    return $retval;
}


sub _flatten_map {
    my ($map, $prefix) = @_;

    $prefix ||= '';
    my %retval = ();

    for my $key (keys %$map) {

        my $value = $map->{$key};
        if (ref $value eq 'ARRAY') {
            my $counter = 1;
            my %copy = map { my $key = ref $_ ? $counter ++ : $_; $key => $_ } @$value;
            $value = \%copy;
        }
        if (ref $value ne 'HASH') {
            $value ||= '';
            $value = "$value";
        }
        if (ref $value) {
            %retval = (%retval, %{_flatten_map($value, "$prefix/$key")});
        }
        else {
            $retval{"$prefix/$key"} = $value;
        }
    }
    return \%retval;
}


1;
