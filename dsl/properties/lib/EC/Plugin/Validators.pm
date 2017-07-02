package EC::Plugin::Validators;

use strict;
use warnings;

use base qw(EC::Plugin::ValidatorsCore);

=head1 SYNOPSYS

Validators are used to validate input parameters (check format, for example).
In config they are described in the following manner:

    property: startDate
    type: entry
    validators:
        - date

The validator may look like:

    sub date {
        my ($self, $value) = @_;

        if ($value =~ m/\d{4}-\d{2}-\d{2}/) {
            # If everything is ok, undef is returned
            return;
        }
        else {
            # Otherwise the error text is returned
            return "$value has wrong date format";
        }
    }

No validators defined by default.

=cut

#checks if value is integer only if it is set
sub is_int {
    my ($self, $value) = @_;

    if ($value){
        my $initial_length = length($value);
        eval { $value = 0 + $value };
        return "Value is not Integer" if $@;
        my $tmp_var = $value;
        return "Value is a string or has blank symbols" if (length("$tmp_var") != $initial_length);
    }
    return;
}

1;
