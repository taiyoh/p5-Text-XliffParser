package Text::XliffParser;

use Any::Moose;
use utf8;

our $VERSION = '0.01';

use XML::SAX::ParserFactory;
use File::Slurp;
use Storable qw/thaw nfreeze/;
use Digest::SHA1 qw/sha1_hex/;

has [qw/file store_dir/] => ( is => 'ro', isa => 'Str', required => 1, );

has stored => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $path = sha1_hex($self->file);
        my $dir  = $self->store_dir || '/tmp';
        return $dir . "/xliffdump_${path}.dmp";
    }
);

has units => (
    is   => 'rw',
    isa  => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        if (-e $self->stored) {
            my $frozen = read_file($self->stored);
            return thaw($frozen);
        }
        else {
            my $p = XML::SAX::ParserFactory->parser(Handler => Text::XliffParser::Handler->new);
            $p->parse_uri($self->file);
            my $units = Text::XliffParser::Handler->get_units;
            write_file($self->stored, nfreeze($units));
            return $units;
        }
    }
);

no Any::Moose;

sub get {
    my $self = shift;
    my $key  = shift or return $self->units;
    return $self->units->{$key};
}

__PACKAGE__->meta->make_immutable;

package Text::XliffParser::Handler;

use utf8;
use base 'XML::SAX::Base';

my $units = {};
my $stash = {};
my $current_element = '';

sub start_element {
    my ($self, $el, %attrs) = @_;

    $current_element = $el->{Name};
}

sub end_element {
    my ($self, $el) = @_;

    $current_element = '';
    if ($el->{Name} eq 'trans-unit') {
        $units->{$stash->{source}} = $stash->{target};
        $stash = {};
    }
}

sub characters {
    my ($self, $data) = @_;

    return unless $current_element =~ /(source|target)/;
    $stash->{$current_element} = $data->{Data};
}

sub get_units { $units }

1;

__END__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xliff PUBLIC "-//XLIFF//DTD XLIFF//EN" "http://www.oasis-open.org/committees/xliff/documents/xliff.dtd">
<xliff version="1.0">
  <file source-language="en" target-language="es" datatype="plaintext" original="messages" product-name="messages">
    <header/>
    <body>
      <trans-unit id="1">
        <source>Welcome to</source>
        <target>Bienvenido a</target>
      </trans-unit>
      <trans-unit id="2">
        <source>Use a valid username and password to gain access to the administration console.</source>
        <target>Utilice un nombre de usuario y contraseña válidos para acceder al panel de administración.</target>
      </trans-unit>
      <trans-unit id="3">
        <source>Username</source>
        <target>Usuario</target>
      </trans-unit>
      <trans-unit id="4">
        <source>Remember?</source>
        <target>Recordar?</target>
      </trans-unit>
    </body>
  </file>
</xliff>
