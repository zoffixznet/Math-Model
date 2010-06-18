use v6;

class Math::Model;

use Math::RungeKutta;

has %.derivatives;
has %.variables;
has %.initials;
has @.captures;

method integrate($from = 0, $to = 10) {
    my %deriv-keying = %.derivatives.keys Z=> 0..Inf;
    my @derivs;
    my @initial;
    for %.initials.pairs {
        @initial[%deriv-keying{.key}] = .value;
    }
    for %.derivatives.pairs {
        @derivs[%deriv-keying{.key}]  = .value;
    }

    my sub param-names(&c) {
        &c.signature.params».name».substr(1).grep: * !eq '_';
    }

    sub derivatives($time, @values) {
        my sub params-for(&c) {
            my %params;
            for param-names(&c) -> $p {
                my $value;
                if $p eq 'time' {
                    $value = $time;
                } elsif %.derivatives.exists($p) {
                    $value = @values[%deriv-keying{$p}];
                } elsif %.variables.exists($p) {
                    my $c = %.variables{$p};
                    $value = $c.(|params-for($c));
                } else {
                    die "Don't know where to get '$p' from.";
                }
                %params{$p} = $value;
            }
            return %params;
        }
        my @res = @values.keys.map: -> $i {
            my $d      = @derivs[$i];
            my %params = params-for($d);
            $d(|%params);
        };
        @res;
    }

    adaptive-rk-integrate(
        :$from,
        :$to,
        :@initial,
        :derivative(&derivatives),
        :max-stepsize(0.2),
        :do(->$t, @v { say "$t\t@v[]"}),
    );
}

# vim: ft=perl6
