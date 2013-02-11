package Play::Events;

use Moo;
use Play::Mongo;
use Params::Validate qw(:all);

use Email::Simple;
use Email::Sender::Simple qw(sendmail);
use Encode qw(encode_utf8);

has 'collection' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return Play::Mongo->db->get_collection('events');
    },
);

sub _prepare_event {
    my $self = shift;
    my ($event) = @_;
    $event->{ts} = $event->{_id}->get_time;
    $event->{_id} = $event->{_id}->to_string;
    return $event;
}

sub add {
    my $self = shift;
    my ($event) = validate_pos(@_, { type => HASHREF });

    my $id = $self->collection->insert($event);
    return 1;
}

sub email {
    my $self = shift;
    my ($address, $subject, $body) = validate_pos(@_, { type => SCALAR }, { type => SCALAR }, { type => SCALAR });

    my $email = Email::Simple->create(
        header => [
            To => $address,
            From => 'Play Perl <notification@play-perl.org>', # TODO - take from config
            Subject => $subject,
            'Reply-to' => 'Vyacheslav Matyukhin <me@berekuk.ru>', # TODO - take from config
            'Content-Type' => 'text/html; charset=utf-8',
        ],
        body => encode_utf8($body),
    );

    # Errors are ignored for now. (It's better than "500 Internal Error" responses)
    # TODO - introduce some kind of local asyncronous queue.
    eval {
        sendmail($email);
    };
}

# returns last 100 events
# TODO: pager
sub list {
    my $self = shift;
    validate_pos(@_);

    my @events = $self->collection->query->sort({ _id => -1 })->limit(100)->all;
    $self->_prepare_event($_) for @events;

    return \@events;
}

1;
