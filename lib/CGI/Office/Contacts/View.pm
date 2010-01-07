package CGI::Office::Contacts::View;

use CGI::Office::Contacts::View::Notes;
use CGI::Office::Contacts::View::Organization;
use CGI::Office::Contacts::View::Person;
use CGI::Office::Contacts::View::Report;

use Moose;

extends 'CGI::Office::Contacts::View::Base';

has notes        => (is => 'rw', isa => 'CGI::Office::Contacts::View::Notes');
has organization => (is => 'rw', isa => 'CGI::Office::Contacts::View::Organization');
has person       => (is => 'rw', isa => 'CGI::Office::Contacts::View::Person');
has report       => (is => 'rw', isa => 'Any');

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	# init is called in this way so that both this module and
	# CGI::Office::Contacts::Donations::View will use the
	# appropriate config and db parameters to initialize their
	# attributes.

	$self -> init;

}	# End of BUILD.

# -----------------------------------------------

sub build_display_detail_js
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_display_detail_js');

	my($js) = $self -> load_tmpl('display.detail.js');

	$js -> param(form_action => ${$self -> config}{'form_action'});
	$js -> param(sid         => $self -> session -> id);

	return $js -> output;

} # End of build_display_detail_js.

# --------------------------------------------------

sub init
{
	my($self) = @_;

	$self -> log(debug => 'Entered init');

	$self -> notes(CGI::Office::Contacts::View::Notes -> new
	(
		config    => $self -> config,
		db        => $self -> db,
		logger    => $self -> logger,
		session   => $self -> session,
		tmpl_path => $self -> tmpl_path,
	) );

	$self -> organization(CGI::Office::Contacts::View::Organization -> new
	(
		config    => $self -> config,
		db        => $self -> db,
		logger    => $self -> logger,
		session   => $self -> session,
		tmpl_path => $self -> tmpl_path,
	) );

	$self -> person(CGI::Office::Contacts::View::Person -> new
	(
		config    => $self -> config,
		db        => $self -> db,
		logger    => $self -> logger,
		session   => $self -> session,
		tmpl_path => $self -> tmpl_path,
	) );

	$self -> report(CGI::Office::Contacts::View::Report -> new
	(
		config    => $self -> config,
		db        => $self -> db,
		logger    => $self -> logger,
		session   => $self -> session,
		tmpl_path => $self -> tmpl_path,
	) );

} # End of init.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
