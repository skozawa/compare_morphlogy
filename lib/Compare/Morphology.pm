package Compare::Morphology;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to(controller => 'root', action => 'index');
  $r->get('/analysis')->to(controller => 'root', action => 'index');
  $r->post('/analysis')->to(controller => 'root', action => 'analysis');
}

1;
