package RplusAccounts;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Plugins
  $self->plugin('Config' => {file => 'app.conf'});

  # Router
  my $r = $self->routes;

  # API namespace
  $r->route('/api/:controller')->under->to(cb => sub {
      my $self = shift;
      return 1;
      return 1 if $self->session('user');
      $self->render(json => {error => 'Unauthorized'}, status => 401);
      return undef;
  })->route('/:action')->to(namespace => 'RplusAccounts::Controller::API');

  # Base namespace
  my $r2 = $r->route('/')->to(namespace => 'RplusAccounts::Controller');
  {
      # Authentication
      $r2->post('/signin')->to('authentication#signin');
      $r2->get('/signout')->to('authentication#signout');

      my $r2b = $r2->under->to(controller => 'authentication', action => 'auth');

      # Main controller
      $r2b->get('/')->to(template => 'main/index');

      # Other controllers
      $r2b->get('/:controller/:action')->to(action => 'index');
  }
}

1;
