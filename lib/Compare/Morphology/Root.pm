package Compare::Morphology::Root;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Text::MeCab;
use Encode;

use constant {
    IPADIC_DIR    => '/usr/local/lib/mecab/dic/ipadic',
    NAIST_DIC_DIR => '/usr/local/lib/mecab/dic/naist-jdic',
    UNIDIC_DIR    => '/usr/local/lib/mecab/dic/unidic',
};

# This action will render a template
sub index {
  my $self = shift;
  # Render template "example/welcome.html.ep" with message
  $self->render(
      'index',
      target_body => "",
      results     => {},
  );
}

sub analysis {
    my $self = shift;

    my $text = $self->param('body');
    my $results = {
        mecab_ipadic   => $self->_mecab($text, IPADIC_DIR),
        mecab_naistdic => $self->_mecab($text, NAIST_DIC_DIR),
        mecab_unidic   => $self->_mecab($text, UNIDIC_DIR)
    };
    $self->check_diff($results);

    $self->render(
        'index',
        target_body => $self->param('body'),
        results     => $results,
    );
}

sub _mecab {
    my ($self, $text, $dicdir) = @_;

    my $mecab = Text::MeCab->new(
        dicdir => $dicdir
    );

    my $morphs = [];
    for ( my $node = $mecab->parse($text); $node; $node = $node->next) {
        push @$morphs, {
            surface => decode_utf8($node->surface),
        };
    }

    return $morphs;
}

sub check_diff {
    my ($self, $results) = @_;

    my @pattern = keys %$results;
    for my $i ( -1 .. $#pattern-1 ) {
        my $result1 = $results->{$pattern[$i]};
        my $result2 = $results->{$pattern[$i+1]};
        my $diff = $self->_diff($result1, $result2);
        $result1->[$_]->{diff}++ for (@{$diff->{array1}});
        $result2->[$_]->{diff}++ for (@{$diff->{array2}});
    }
}

sub _diff {
    my ($self, $array1, $array2) = @_;

    my $lengths = { array1 => 0, array2 => 0 };
    my $diffs = { array1 => [], array2 => [] };
    my $j = 0;
    for my $i ( 0 .. $#{$array1} ) {
        if ( $lengths->{array1} < $lengths->{array2} ) {
            push @{$diffs->{array1}}, $i;
            $lengths->{array1} += length $array1->[$i]->{surface};
            next;
        }
        my $word1 = $array1->[$i]->{surface};
        my $word2 = $array2->[$j]->{surface};
        $lengths->{array1} += length $word1;
        $lengths->{array2} += length $word2;
        if ( $lengths->{array1} != $lengths->{array2} || $word1 ne $word2 ) {
            push @{$diffs->{array1}}, $i;
            push @{$diffs->{array2}}, $j;
        }
        $j++;
        while ( $lengths->{array1} > $lengths->{array2} ) {
            push @{$diffs->{array2}}, $j;
            $lengths->{array2} += length $array2->[$j]->{surface};
            $j++;
        }
    }
    for ( $j .. $#{$array2} ) {
        push @{$diffs->{array2}}, $_;
    }

    return $diffs;
}

1;
