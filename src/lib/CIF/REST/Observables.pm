package CIF::REST::Observables;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    my $query      	= $self->param('q') || $self->param('observable');
    
    my $res = $self->cli->search({
        token      	=> $self->param('token'),
        query      	=> $query,
        filters     => {
        	otype          => $self->param('otype')        || undef,
        	cc             => $self->param('cc')           || undef,
        	confidence     => $self->param('confidence')   || 0,
        	starttime      => $self->param('starttime')    || undef,
        	group          => $self->param('group')        || undef,
        	limit          => $self->param('limit')        || undef,
        	tags           => $self->param('tags')         || undef,
        	application    => $self->param('application')  || undef,
        	asn            => $self->param('asn')          || undef,
        	provider       => $self->param('provider')     || undef,
        	rdata          => $self->param('rdata')        || undef,
        	starttime      => $self->param('firsttime')    || undef,
        },
    });
    $self->stash(observables => $res, token => $self->param('token')); ##TODO is this safe?
    $self->respond_to(
        json    => { json => $res },
        html    => { template => 'observables/index' },
    );
}

sub show {
    my $self  = shift;
    
    my $res = $self->cli->search({
        token      => $self->param('token'),
        id         => $self->stash->{'observable'},
    });
    $self->stash(observables => $res); ##TODO -- does this leak if we don't clear it?
    $self->respond_to(
        json    => { json => $res },
        html    => { template => 'observables/show' },
    );
}

sub create {
    my $self = shift;
    
    my $data = $self->req->json();
    
    ##TODO client should spin this out to a queue
    my $res = $self->cli->submit({
        token           => $self->param('token'),
        observables     => $data,
        enable_metadata => 1,
    });
    
    if($res == -1){
        $self->respond_to(
            json => { json => { "error" => "timeout" }, status => 408 },
        );
        return;
    }
    
    $self->res->headers->add('X-Location' => $self->req->url->to_string());
    $self->res->headers->add('X-Id' => @{$res}[0]); ## TODO
    
    $self->respond_to(
        json    => { json => $res, status => 201 },
    );
}

1;
