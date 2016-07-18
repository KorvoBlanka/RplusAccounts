package RplusAccounts::Controller::API::Account;

use Mojo::Base 'Mojolicious::Controller';

use Rplus::DB;

use Rplus::Model::Account::Manager;
use Rplus::Model::Location::Manager;

my $dbh = Rplus::DB->new_or_cached->dbh;

my $ua = Mojo::UserAgent->new;

sub log_event {
    my $text = shift;
    my $account = shift;
}

sub set_color_tag {
    my $self = shift;
    my $id = $self->param('id');
    my $color_tag = $self->param('color_tag');

    my $account = Rplus::Model::Account::Manager->get_objects(query => [id => $id, del_date => undef])->[0];
    return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

    if ($account->color_tag == $color_tag) {
        $account->color_tag(undef);
    } else {
        $account->color_tag($color_tag);
    }
    $account->save;

    return $self->render(json => {status => 'success', color_tag => $account->color_tag});
}

sub list {
    my $self = shift;

    my $res = {
        count => 0,
        list => [],
    };

    my $account_iter = Rplus::Model::Account::Manager->get_objects_iterator(query => [del_date => undef], sort_by => 'id');
    while (my $account = $account_iter->next) {
        my $x = {
            id => $account->id,
            email => $account->email,
            subdomain => $account->name,
            user_count => $account->user_count,
            mode => $account->mode,
            balance => $account->balance,
            reg_date => $account->reg_date,
        };
        push @{$res->{list}}, $x;
    }

    $res->{count} = scalar @{$res->{list}};

    return $self->render(json => $res);
}

sub get {
    my $self = shift;
    my $id = $self->param('id');

    my $account = Rplus::Model::Account::Manager->get_objects(query => [id => $id, del_date => undef])->[0];
    return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

    my $res = {
            id => $account->id,
            email => $account->email,
            password => $account->password,
            subdomain => $account->name,
            user_count => $account->user_count,
            balance => $account->balance,
            reg_date => $account->reg_date,
            discount => $account->discount,
            discount_end_date => $account->discount_end_date,
    };

    return $self->render(json => $res);
}

sub get_by_name {
    my $self = shift;
    my $name = $self->param('name');

    my $account = Rplus::Model::Account::Manager->get_objects(query => [name => $name, del_date => undef])->[0];
    return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

    my $res = {
        name => $account->name,
        balance => $account->balance,
        user_count => $account->user_count,
        mode => $account->mode,
        location_id => $account->location_id,
    };

    return $self->render(json => {status => 'ok', data => $res});
}

sub delete {
    my $self = shift;
    my $id = $self->param('id');

    my $account = Rplus::Model::Account::Manager->get_objects(query => [id => $id, del_date => undef])->[0];
    return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

    $account->del_date('now()');
    $account->save(changes_only => 1);

    return $self->render(json => {status => 'success', });
}

sub save {
    my $self = shift;

    my $email = $self->param('email');
    my $password = $self->param('password');
    my $subdomain = $self->param('subdomain');
    my $user_count = $self->param('user_count');
    my $balance = $self->param('balance');
    my $discount = $self->param('discount');
    my $discount_end_date = $self->param('discount_end_date');

    my $account;

    if (my $id = $self->param('id')) {
        $account = Rplus::Model::Account::Manager->get_objects(query => [id => $id, del_date => undef])->[0];
    }

    return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

    # Save
    $account->email($email);
    $account->password($password);
    $account->name($subdomain);
    $account->balance($balance);
    $account->user_count($user_count);
    $account->discount($discount);
    $account->discount_end_date($discount_end_date);

    eval {
        $account->save($account->id ? (changes_only => 1) : (insert => 1));
        1;
    } or do {
        return $self->render(json => {error => $@}, status => 500);
    };

    return $self->render(json => {status => 'success', });
}

sub create {
  my $self = shift;

  # Input params
  my $email = $self->param('email');
  my $account_name = $self->param('account_name');
  my $password = $self->param('password');
  my $mode = $self->param('mode');
  my $location_id = $self->param('location_id');


  # Create account
  my $account = Rplus::Model::Account->new;

  # Save
  $account->email($email);
  $account->name($account_name);
  $account->password($password);
  $account->mode($mode);
  $account->location_id($location_id);

  $account->save();

  unless ($account_name) {
    $account->name('account' . $account->id);
    $account->save(changes_only => 1);
  }

  my $location = Rplus::Model::Location::Manager->get_objects(query => [id => $account->location_id])->[0];
  my $server_name = $location->server_name;
  my $service_url = "http://$server_name/service/create_account";

  say $service_url;

  my $tx = $ua->get($service_url, form => {
      email => $account->email,
      name =>  $account->name,
      location_id => $account->location_id,
  });

  return $self->render(json => {status => 'success'});
}

sub add_sum {
    my $self = shift;

    my $id = $self->param('id');
    my $sum = $self->param('sum');

    my $account = Rplus::Model::Account::Manager->get_objects(query => [id => $id, del_date => undef])->[0];
    return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

    $account->balance($account->balance + $sum);
    $account->save(changes_only => 1);

    return $self->render(json => {status => 'success', });
}

sub list_users {
  my $self = shift;

  my $id = $self->param('id');
  my $account = Rplus::Model::Account::Manager->get_objects(query => [id => $id, del_date => undef])->[0];
  return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

  my $location = Rplus::Model::Location::Manager->get_objects(query => [id => $account->location_id])->[0];
  my $server_name = $location->server_name;
  my $service_url = "http://$server_name/service/list_users";

  my $tx = $ua->get($service_url, form => {
      account_name =>  $account->name,
  });

  return $self->render(json => $tx->res->json);
}

sub reset_usr_password {
  my $self = shift;

  my $id = $self->param('id');
  my $user_id = $self->param('user_id');

  my $account = Rplus::Model::Account::Manager->get_objects(query => [id => $id, del_date => undef])->[0];
  return $self->render(json => {error => 'Not Found'}, status => 404) unless $account;

  my $location = Rplus::Model::Location::Manager->get_objects(query => [id => $account->location_id])->[0];
  my $server_name = $location->server_name;
  my $service_url = "http://$server_name/service/reset_usr_pwd";

  my $tx = $ua->get($service_url, form => {
      id => $user_id,
  });

  return $self->render(json => $tx->res->json);
}

1;
