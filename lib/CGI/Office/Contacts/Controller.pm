package CGI::Office::Contacts::Controller;

use base 'CGI::Office::Contacts';
use strict;
use warnings;

use CGI::Office::Contacts::Database;
use CGI::Office::Contacts::Util::Config;
use CGI::Office::Contacts::View;

use Log::Dispatch;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.01';

# -----------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;

	# Outputs nothing, since logger not yet set up.
	#$self -> log(debug => 'Entered cgiapp_prerun');

	$self -> param(config => CGI::Office::Contacts::Util::Config -> new -> config);

	# Set up half the logger, but don't use it until the dbh is available.

	$self -> param(logger => Log::Dispatch -> new);

	# Set up the database.

	$self -> param(db => CGI::Office::Contacts::Database -> new
	(
		config => $self -> param('config'),
		logger => $self -> param('logger'),
	) );

	# Set up the things shared by:
	# o CGI::Office::Contacts
	# o CGI::Office::Contacts::Donations
	# o CGI::Office::Contacts::Import::vCards

	$self -> global_prerun;

	# Set up the view.

	$self -> param(view => CGI::Office::Contacts::View -> new
	(
		config    => $self -> param('config'),
		db        => $self -> param('db'),
		logger    => $self -> param('logger'),
		session   => $self -> param('session'),
		tmpl_path => $self -> tmpl_path,
	) );

} # End of cgiapp_prerun.

# -----------------------------------------------

1;
