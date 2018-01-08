package App::Genpass::WordList;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Random::Any 'rand', -warn => 1;
use App::wordlist ();
use List::Util qw(shuffle);

our %SPEC;

my $symbols = [split //, q(~`!@#$%^&*()_-+={}[]|\\:;"'<>,.?/)];
my $digits = ["0".."9"];
my $alphanums = ["A".."Z", "a".."z", "0".."9"];

my $default_patterns = [
    '%w %w %w',
    '%w %w %w %w',
    '%w %w %w %w %w',
    '%w %w %w %w %w %w',
    '%W%4d%W',
    '%W%6d%s',
];

our %arg_patterns = (
    patterns => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'pattern',
        summary => 'Pattern(s) to use',
        schema => ['array*', of=>'str*', min_len=>1],
        description => <<'_',

A pattern is string that is similar to a printf pattern. %P (where P is certain
letter signifying a format) will be replaced with some other string. %NP (where
N is a number) will be replaced by a word of length N, %N$Mw (where N and M is a
number) will be replaced by a word of length between N and M. Anything else will
be used as-is. Available conversions:

    %w   Random word, all lowercase.
    %W   Random word, first letter uppercase, the rest lowercase.
    %s   Random ASCII symbol, e.g. "-" (dash), "_" (underscore), etc.
    %d   Random digit (0-9).
    %a   Random alphanumeric character (A-Z, a-z, 0-9)
    %%   A literal percent sign.

_
        default => $default_patterns,
        cmdline_aliases => {p=>{}},
    },
);

sub _fill_conversion {
    my ($matches, $words) = @_;

    my $n = $matches->{N};
    my $m = $matches->{M};
    my $len = defined($n) && defined($m) ? $n+int(rand()*($m-$n+1)) :
        defined($n) ? $n : 1;

    if ($matches->{CONV} eq '%') {
        return join("", map {'%'} 1..$len);
    } elsif ($matches->{CONV} eq 's') {
        return join("", map {$symbols->[rand(@$symbols)]} 1..$len);
    } elsif ($matches->{CONV} eq 'a') {
        return join("", map {$alphanums->[rand(@$alphanums)]} 1..$len);
    } elsif ($matches->{CONV} eq 'w' || $matches->{CONV} eq 'W') {
        die "Ran out of words while trying to fill out conversion '$matches->{all}'" unless @$words;
        my $i = 0;
        my $word;
        while ($i < @$words) {
            if (defined $n && defined $m) {
                if (length($words->[$i]) >= $n && length($words->[$i]) <= $m) {
                    $word = splice @$words, $i, 1;
                    last;
                }
            } elsif (defined $n) {
                if (length($words->[$i]) == $n) {
                    $word = splice @$words, $i, 1;
                    last;
                }
            } else {
                $word = splice @$words, $i, 1;
                last;
            }
            $i++;
        }
        die "Couldn't find suitable random words for conversion '$matches->{all}'"
            unless defined $word;
        $word = lc $word;
        if ($matches->{CONV} eq 'W') {
            return ucfirst $word;
        } else {
            return $word;
        }
    } elsif ($matches->{CONV} eq 'd') {
        return join("", map {$digits->[rand(@$digits)]} 1..$len);
    }
}

sub _fill_pattern {
    my ($pattern, $words) = @_;

    $pattern =~ s/(?<all>%(?:(?<N>\d+)(?:\$(?<M>\d+))?)?(?<CONV>[Wwds%]))/
        _fill_conversion({%+}, $words)/eg;

    $pattern;
}

$SPEC{genpass} = {
    v => 1.1,
    summary => 'Generate password with words from WordList::*',
    description => <<'_',

Using password from dictionary words (in this case, from WordList::*) can be
useful for humans when remembering the password. Note that using a string of
random characters is generally better because of the larger space (combination).
Using a password of two random words from a 5000-word wordlist has a space of
only ~25 million while an 8-character of random uppercase letters/lowercase
letters/numbers has a space of 62^8 = ~218 trillion. To increase the space
you'll need to use more words (e.g. 3 to 5 instead of just 2). This is important
if you are using the password for something that can be bruteforced quickly e.g.
for protecting on-disk ZIP/GnuPG file and the attacker has access to your file.
It is then recommended to use a high number of rounds for hashing to slow down
password cracking (e.g. `--s2k-count 65011712` in GnuPG).

_
    args => {
        num => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        %App::wordlist::arg_wordlists,
        %arg_patterns,
    },
    examples => [
    ],
};
sub genpass {
    my %args = @_;

    my $num = $args{num} // 1;
    my $wordlists = $args{wordlists} // ['EN::Enable'];
    my $patterns = $args{patterns} // $default_patterns;

    my $res = App::wordlist::wordlist(
        (wordlists => $wordlists) x !!defined($wordlists),
    );
    return $res unless $res->[0] == 200;

    my @words = shuffle @{ $res->[2] };

    my @passwords;
    for my $i (1..$num) {
        push @passwords,
            _fill_pattern($patterns->[rand @$patterns], \@words);
    }

    [200, "OK", \@passwords];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See the included script L<genpass-wordlist>.
