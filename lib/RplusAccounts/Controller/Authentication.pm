package RplusAccounts::Controller::Authentication;

use Mojo::Base 'Mojolicious::Controller';

use Rplus::Model::User;
use Rplus::Model::User::Manager;
use Mojo::Log;
 
my $log = Mojo::Log->new;

sub auth {
    my $self = shift;
    
    return 1 if $self->session('user') && $self->session('user')->{'id'};

    $self->render(template => 'authentication/signin');
    return undef;
}

sub signin {
    my $self = shift;

    my $login = $self->param('login');
    my $password = $self->param('password');
    my $remember_me = $self->param('remember_me');

    return $self->render(json => {status => 'failed'}) unless $login && defined $password;

    my $user = Rplus::Model::User::Manager->get_objects(query => [login => $login, password => $password, del_date => undef])->[0];
    return $self->render(json => {status => 'failed'}) unless $user;

    $self->session->{'user'} = {
        id => $user->id,
        login => $user->login,
    };

    if ($remember_me) {
        $self->session(expiration => 604800);
    } else {
        $self->session(expiration => 3600); # default expiration
    }

    return $self->render(json => {status => 'success'});
}

sub signout {
    my $self = shift;

    delete $self->session->{'user'};

    return $self->redirect_to('/');
}

1;
