package CGI::Office::Contacts::Base;

use Moose;

has logger => (is => 'ro', isa => 'Log::Dispatch', required => 1);

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------
# This sub is copied from CGI::Office::Controller.
# This version is for Moose-base modules.
# CGI::Application-based modules have their own version.

sub log
{
	my($self, $level, $s) = @_;

	if ($self -> logger)
	{
		if ($s)
		{
			$s = (caller)[0] . ". $s";
			$s =~ s/^CGI::Office::Contacts/\*/;
		}
		else
		{
			$s = '';
		}

		$self -> logger -> log(level => $level, message => $s);
	}

} # End of log.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
