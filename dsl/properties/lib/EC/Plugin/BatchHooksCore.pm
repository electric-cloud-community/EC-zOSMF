package EC::Plugin::BatchHooksCore;

use strict;
use warnings;

use constant {
    AFTER_HOOK => 'after',
    BEFORE_HOOK => 'before',
    PARAMETERS_HOOK => 'parameters',
};

sub new {
    my ($class, $plugin) = @_;

    die 'No plugin' unless $plugin;
    my $self = {batch_hooks_storage => {}, plugin => $plugin};
    return bless $self, $class;
}

sub define_batch_hook {
    my ($self, $step_name, $hook_name, $hook, $options) = @_;

    $self->{batch_hooks_storage}->{$step_name}->{$hook_name} = {hook => $hook, options => $options};
}


sub define_batch_hooks {
    die 'Not implemented'
}

sub before_batch_hook {
    my ($self, $step_name) = @_;
    $self->_run($step_name, BEFORE_HOOK);
}

sub after_batch_hook {
    my ($self, $step_name) = @_;
    $self->_run($step_name, AFTER_HOOK);
}

sub parameters_batch_hook {
    my ($self, $step_name, $parameters) = @_;
    $self->_run($step_name, PARAMETERS_HOOK, $parameters);
}


sub _get_batch_hook {
    my ($self, $step_name, $hook_name) = @_;
    return $self->{batch_hooks_storage}->{$step_name}->{$hook_name}->{hook};
}

sub _get_batch_hook_options {
    my ($self, $step_name, $hook_name) = @_;

    return $self->{batch_hooks_storage}->{$step_name}->{$hook_name}->{options} || {};
}

sub _run {
    my $self = shift;
    my $step_name = shift;
    my $hook_name = shift;
    my @options = @_;

    my $shared_hook = $self->{batch_hooks_storage}->{'*'}->{$hook_name}->{hook};
    my $own_hook = $self->_get_batch_hook($step_name, $hook_name);

    my $own_hook_options = $self->_get_batch_hook_options($step_name, $hook_name);
    $self->{main_parameters} = { %{$self->plugin->parameters($step_name)} };

    my @hooks = ();
    if ($own_hook_options->{run_before_shared}) {
        push @hooks, $own_hook, $shared_hook;
    }
    else {
        push @hooks, $shared_hook, $own_hook;
    }

    my $do_more;
    my $iter_num = 0;
    return sub {
        if ($iter_num > 0){
            return undef unless $do_more;
        }

        for my $hook (@hooks) {
            if ($hook) {
                $self->{'iter_num'} = $iter_num;
                $do_more = $hook->($self, @options);
            }
        }
        
        return ++$iter_num;   
    };
}

sub plugin {
    return shift->{plugin};
}

1;
