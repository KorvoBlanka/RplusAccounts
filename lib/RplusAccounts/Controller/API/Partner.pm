package RplusAccounts::Controller::API::Partner;

use Mojo::Base 'Mojolicious::Controller';

use Rplus::DB;

use Rplus::Model::Partner::Manager;

my $dbh = Rplus::DB->new_or_cached->dbh;

my $ua = Mojo::UserAgent->new;

sub log_event {
    my $text = shift;
    my $account = shift;
}


sub list {
    my $self = shift;

    my $res = {
        count => 0,
        list => [],
    };

    return $self->render(json => {status => 'not implemented yet', });
}

sub get {
    my $self = shift;
    my $id = $self->param('id');

    my $partner = Rplus::Model::Partner::Manager->get_objects(query => [id => $id])->[0];
    return $self->render(json => {error => 'Not Found'}, status => 404) unless $partner;

    my $res = {
            id => $partner->id,
            name => $partner->name,
            code => $partner->code,
            balance_bonus => $partner->balance_bonus,
            active => $partner->active,
            add_date => $partner->add_date,
    };

    return $self->render(json => $res);
}

sub delete {
    my $self = shift;
    my $id = $self->param('id');

    return $self->render(json => {status => 'not implemented yet', });
}

sub save {
    my $self = shift;

    my $id = $self->param('id');
    my $name = $self->param('name');
    my $code = $self->param('code');
    my $balance_bonus = $self->param('balance_bonus');
    my $active = $self->param('active');

    my $partner;

    if (my $id = $self->param('id')) {
        $partner = Rplus::Model::Partner::Manager->get_objects(query => [id => $id])->[0];
        return $self->render(json => {error => 'Not Found'}, status => 404) unless $partner;
    } else {
        $partner = Rplus::Model::Partner->new;
    }


    # Save
    $partner->name($name);
    $partner->code($code);
    $partner->balance_bonus($balance_bonus);
    $partner->active($active);

    eval {
        $partner->save();
        1;
    } or do {
        return $self->render(json => {error => $@}, status => 500);
    };

    return $self->render(json => {status => 'success', });
}

1;
