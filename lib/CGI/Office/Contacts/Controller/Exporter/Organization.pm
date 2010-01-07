package CGI::Office::Contacts::Controller::Exporter::Organization;

use strict;
use warnings;

use CGI::Office::Contacts::Util::Validator;

use JSON::XS;

use Sub::Exporter -setup =>
{
	exports =>
	[qw/
		add
		cgiapp_init
		delete_occupation_via_organization
		display
		organization_autocomplete
		update
	/],
};

our $VERSION = '1.01';

# -----------------------------------------------

sub add
{
	my($self) = @_;

	$self -> log(debug => 'Entered add');

	my($result) = CGI::Office::Contacts::Util::Validator -> new
	(
		config => $self -> param('config'),
		db     => $self -> param('db'),
		query  => $self -> query,
	) -> organization;

	return $self -> param('view') -> organization -> report_add($self -> param('user_id'), $result);

} # End of add.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete_occupation_via_organization
{
	my($self) = @_;

	$self -> log(debug => 'Entered delete_occupation_via_organization');

	my($id)            = $self -> query -> param('target_id');
	my($organization)  = $self -> param('db') -> organization -> get_organization_via_id($id);
	my(@occupation_id) = split(/,/, $self -> occupation_id);

	# Discard the 0.
	# See update.organization.js's function <tmpl_var name=context>_organization_staff_onsubmit() for details.

	shift @occupation_id;

	my($result) = $self -> param('db') -> occupation -> delete_via_organization($id, @occupation_id);

	if ($result > 0)
	{
		$result = "Deleted $result occupation" . ($result == 1 ? '' : 's') . " for '$$organization{'name'}' (Hint: Refresh via Search tab)";
	}
	else
	{
		$result = "No such occupation for $$organization{'name'}";
	}

	return $result;

} # End of delete_occupation_via_organization.

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'Entered display');

	my($id)           = $self -> query -> param('target_id');
	my($organization) = $self -> param('db') -> organization -> get_organization($self -> param('user_id'), $id);
	my($result)       = "No organization has the requested id. (Hint: Run another search)";

	if ($id && ($#$organization >= 0) )
	{
		$result = $self -> param('view') -> organization -> build_update_organization_html($id, $$organization[0]);
	}

	return $result;

} # End of display.

# -----------------------------------------------

sub organization_autocomplete
{
	my($self) = @_;

	$self -> log(debug => 'Entered organization_autocomplete');

	my($json) = JSON::XS -> new;
	my($name) = $self -> query -> param('name') || ''; # TODO
	my($list) = $self -> param('db') -> organization -> get_organizations_via_name_prefix($name);

	if ($#$list < 0)
	{
		$list = [ [$name, 0] ];
	}

	return $json -> encode({results => [map{ {name => $$_[0], id => $$_[1]} } @$list]});

} # End of organization_autocomplete.

# -----------------------------------------------

sub update
{
	my($self) = @_;

	$self -> log(debug => 'Entered update');

	my($id)           = $self -> query -> param('target_id'); # TODO
	my($action)       = $self -> query -> param('submit_organization_delete') || 'Update';
	my($name)         = $self -> query -> param('name') || '';
	my($user_id)      = $self -> param('user_id');
	my($organization) = $self -> param('db') -> organization -> get_organization($user_id, $id);

	my($result);

	if ($#$organization < 0)
	{
		$result = "'$name' not on file";
	}
	elsif ($action eq 'Delete')
	{
		$action       = $self -> param('db') -> organization -> delete($id, $name);
		my($template) = $self -> load_tmpl('update.report.tmpl');

		$template -> param(message => $action);

		$result = $template -> output;
	}
	else # Update.
	{
		my($input) = CGI::Office::Contacts::Util::Validator -> new
		(
			config => $self -> param('config'),
			db     => $self -> param('db'),
			query  => $self -> query,
		) -> organization;

		$result = $self -> param('view') -> organization -> report_update($user_id, $id, $input);
	}

	return $result;

} # End of update.

# -----------------------------------------------

1;
