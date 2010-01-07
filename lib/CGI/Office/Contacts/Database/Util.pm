package CGI::Office::Contacts::Database::Util;

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

has logger    => (is => 'ro', isa => 'Log::Dispatch', required => 1);
has table_map => (is => 'rw', isa => 'HashRef', required => 0);

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------

sub build_brief_error_report
{
	my($self, $result, $template) = @_;

	my(@msg);
	my(@s);

	for my $field ($result -> invalids)
	{
		push @s, "$field: Invalid value: " . ($result -> get_value($field) || '');
	}

	for my $field ($result -> missings)
	{
		push @s, "$field: Missing value";
	}

	return join('. ', @s);

} # End of build_brief_error_report.

# -----------------------------------------------

sub build_error_report
{
	my($self, $result, $template) = @_;

	my(@msg);

	for my $field ($result -> invalids)
	{
		push @msg, "$field: Invalid value: " . ($result -> get_value($field) || '');
	}

	for my $field ($result -> missings)
	{
		push @msg, "$field: Missing value";
	}

	$template -> param(error   => 1);
	$template -> param(tr_loop => [map{ {td => $_} } @msg]);

} # End of build_error_report.

# -----------------------------------------------

sub get_broadcasts
{
	my($self) = @_;

	return $self -> select_map('select name, id from broadcasts');

} # End of get_broadcasts.

# -----------------------------------------------

sub get_communication_types
{
	my($self) = @_;

	return $self -> select_map('select name, id from communication_types');

} # End of get_communication_types.

# -----------------------------------------------

sub get_email_address_types
{
	my($self) = @_;

	return $self -> select_map('select name, id from email_address_types');

} # End of get_email_address_types.

# -----------------------------------------------

sub get_genders
{
	my($self) = @_;

	return $self -> select_map('select name, id from genders');

} # End of get_genders.

# -----------------------------------------------

sub get_phone_number_types
{
	my($self) = @_;

	return $self -> select_map('select name, id from phone_number_types');

} # End of get_phone_number_types.

# -----------------------------------------------

sub get_report_entities
{
	my($self) = @_;

	return $self -> select_map('select name, id from report_entities');

} # End of get_report_entities.

# -----------------------------------------------

sub get_reports
{
	my($self) = @_;

	return $self -> select_map('select name, id from reports');

} # End of get_reports.

# -----------------------------------------------

sub get_role_via_id
{
	my($self, $id) = @_;
	my($role)      = $self -> db -> dbh -> selectrow_hashref('select name from roles where id = ?', {}, $id);

	return $role ? $$role{'name'} : '';

} # End of get_role_via_id.

# -----------------------------------------------

sub get_roles
{
	my($self) = @_;

	return $self -> select_map('select name, id from roles');

} # End of get_roles.

# -----------------------------------------------

sub get_titles
{
	my($self) = @_;

	return $self -> select_map('select name, id from titles');

} # End of get_titles.

# -----------------------------------------------

sub get_yes_no_name
{
	my($self, $id) = @_;
	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from yes_nos where id = ?', {}, $id);

	return $name ? $$name{'name'} : '';

} # End of get_yes_no_name.

# -----------------------------------------------

sub get_yes_nos
{
	my($self) = @_;

	return $self -> db -> dbh -> select_map('select name, id from yes_nos');

} # End of get_yes_nos.

# -----------------------------------------------

sub insert_hash
{
	my($self, $table_name, $field_values) = @_;
	my(@fields) = sort keys %$field_values;
	my(@values) = @{$field_values}{@fields};
	my($sql)    = sprintf 'insert into %s (%s) values (%s)', $table_name, join(',', @fields), join(',', ('?') x @fields);

	$self -> db -> dbh -> do($sql, {}, @values);

} # End of insert_hash.

# -----------------------------------------------

sub insert_hash_get_id
{
	my($self, $table_name, $field_values) = @_;

	$self -> insert_hash($table_name, $field_values);
	$self -> last_insert_id($table_name);

} # End of insert_hash_get_id.

# -----------------------------------------------

sub last_insert_id
{
	my($self, $table_name) = @_;

	return $self -> db -> dbh -> last_insert_id(undef, undef, $table_name, undef);

} # End of last_insert_id.

# -----------------------------------------------

sub select_map
{
	my($self, $sql) = @_;

	return {@{$self -> db -> dbh -> selectcol_arrayref($sql, {Columns=>[1, 2]}) } };

} # End of select_map.

# -----------------------------------------------

sub set_table_map
{
	my($self) = @_;

	$self -> table_map($self -> db -> dbh -> selectall_hashref('select * from table_names', 'name') );

} # End of set_table_map.
# --------------------------------------------------

sub validate_broadcast
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from broadcasts where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_broadcast.

# --------------------------------------------------

sub validate_communication_type
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from communication_types where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_communication_type.

# --------------------------------------------------

sub validate_email_address_type
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from email_address_types where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_email_address_type.

# --------------------------------------------------

sub validate_gender
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from genders where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_gender.

# --------------------------------------------------

sub validate_phone_number_type
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from phone_number_types where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_phone_number_type.

# --------------------------------------------------

sub validate_report
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from reports where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_report.

# --------------------------------------------------

sub validate_report_entity
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from report_entities where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_report_entity.

# --------------------------------------------------

sub validate_role
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from roles where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_role.

# --------------------------------------------------

sub validate_title
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from titles where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_title.

# --------------------------------------------------

sub validate_yes_no
{
	my($self, $value) = @_;
	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from yes_nos where id = ?', {}, $value);

	return $id ? $$id{'id'} : 0;

} # End of validate_yes_no.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
