package App::genpw::base58;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use App::genpw ();
use List::Util qw(shuffle);

our %SPEC;

my $default_patterns = [
    '%w %w %w',
    '%w %w %w %w',
    '%w %w %w %w %w',
    '%w %w %w %w %w %w',
    '%w%4d%w',
    '%w%6d%s',
];

my %args = %{$App::genpw::SPEC{genpw}{args}};
delete $args{patterns};
delete $args{case};

$SPEC{genpw} = {
    v => 1.1,
    summary => 'Generate random password using base58 characters',
    description => <<'_',

_
    args => {
        %args,
    },
    examples => [
    ],
};
sub genpw {
    my %args = @_;

    my $min_len = $args{len} // $args{min_len} // 8;
    my $max_len = $args{len} // $args{max_len} // 20;

    App::genpw::genpw(
        %args,
        patterns => ["%${min_len}\$${max_len}b"],
    );
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See the included script L<genpw-base58>.


=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Base58>

L<genpw> (from L<App::genpw>)
