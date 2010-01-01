package CGI::Office::Contacts::Util::Config;

use Carp;

use Config::Tiny;

use Moose;

has config           => (is => 'rw', isa => 'Any', required => 0);
has config_file_path => (is => 'rw', isa => 'Str', required => 0);
has section          => (is => 'rw', isa => 'Str', required => 0);

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($name) = '.htoffice.contacts.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|CGI/Office/Contacts/Util/Config.pm|);

		($path = $INC{$_}) =~ s|Util/Config.pm|$name|;
	}

	$self -> init($path);

} # End of BUILD.

# -----------------------------------------------

sub init
{
	my($self, $path) = @_;

	$self -> config_file_path($path);

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );
	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		Carp::croak "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		Carp::croak "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of init.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
