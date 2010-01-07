package CGI::Office::Contacts::Database::EmailAddress;

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------

sub delete_email_address_organization
{
	my($self, $creator_id, $id) = @_;

	$self -> log(debug => 'Entered delete_email_address_organization');

	$self -> db -> dbh -> do('delete from email_organizations where id = ?', {}, $id);

} # End of delete_email_address_organization.

# -----------------------------------------------

sub delete_email_address_person
{
	my($self, $creator_id, $id) = @_;

	$self -> log(debug => 'Entered delete_email_address_people');

	$self -> db -> dbh -> do('delete from email_people where id = ?', {}, $id);

} # End of delete_email_address_people.

# -----------------------------------------------

sub get_email_address_id_via_address
{
	my($self, $address) = @_;

	$self -> log(debug => "Entered get_email_address_id_via_address: $address");

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from email_addresses where address = ?', {}, $address);
	$id     = $id ? $$id{'id'} : 0;

	return $id ? $id : 0;

} # End of get_email_address_id_via_address.

# -----------------------------------------------

sub get_email_address_id_via_organization
{
	my($self, $organization_id) = @_;

	$self -> log(debug => "Entered get_email_address_id_via_organization: $organization_id");

	return $self -> db -> dbh -> selectall_arrayref('select id, email_address_id from email_organizations where organization_id = ?', {Slice => {} }, $organization_id) || [];

} # End of get_email_address_id_via_organization.

# -----------------------------------------------

sub get_email_address_id_via_person
{
	my($self, $person_id) = @_;

	$self -> log(debug => "Entered get_email_address_id_via_person: $person_id");

	return $self -> db -> dbh -> selectall_arrayref('select id, email_address_id from email_people where person_id = ?', {Slice => {} }, $person_id) || [];

} # End of get_email_address_id_via_person.

# -----------------------------------------------

sub get_email_address_type_id_via_name
{
	my($self, $name) = @_;

	$self -> log(debug => "Entered get_email_address_type_id_via_name: $name");

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from email_address_types where name = ?', {}, $name);
	$id     = $id ? $$id{'id'} : 0;

	return $id;

} # End of get_email_address_type_id_via_name.

# -----------------------------------------------

sub get_email_address_type_name_via_id
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_email_address_type_name_via_id: $id");

	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from email_address_types where id = ?', {}, $id);
	$name     = $name ? $$name{'name'} : '';

	return $name;

} # End of get_email_address_type_name_via_id.

# -----------------------------------------------

sub get_email_address_via_id
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_email_address_via_id: $id");

	my($address)   = $self -> db -> dbh -> selectrow_hashref('select address, email_address_type_id from email_addresses where id = ?', {}, $id);
	my($name)      = $self -> get_email_address_type_name_via_id($$address{'email_address_type_id'});

	return
	{
		address   => $$address{'address'},
		type_id   => $$address{'email_address_type_id'},
		type_name => $name,
	};

} # End of get_email_address_via_id.

# --------------------------------------------------

sub save_email_address_for_organization
{
	my($self, $context, $organization, $count) = @_;

	$self -> log(debug => 'Entered save_email_address_for_organization');

	my($table_name)                  = 'email_addresses';
	my($email)                       = {};
	$$email{'address'}               = $$organization{"email_$count"};
	$$email{'email_address_type_id'} = $$organization{"email_address_type_id_$count"};
	my($id)                          = $self -> get_email_address_id_via_address($$email{'address'});

	if ($id == 0)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $email);

		$id = $self -> db -> util -> last_insert_id($table_name);
	}

	$table_name                 = 'email_organizations';
	$email                      = {};
	$$email{'email_address_id'} = $id;
	$$email{'organization_id'}  = $$organization{'id'};

	$self -> db -> util -> insert_hash($table_name, $email);
	$self -> db -> util -> last_insert_id($table_name);

} # End of save_email_address_for_organization.

# --------------------------------------------------

sub save_email_address_for_person
{
	my($self, $context, $person, $count) = @_;

	$self -> log(debug => 'Entered save_email_address_for_person');

	my($table_name)                  = 'email_addresses';
	my($email)                       = {};
	$$email{'address'}               = $$person{"email_$count"};
	$$email{'email_address_type_id'} = $$person{"email_address_type_id_$count"};
	my($id)                          = $self -> get_email_address_id_via_address($$email{'address'});

	$self -> log(debug => "Saving email_address: $$email{'address'}");

	if ($id == 0)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $email);

		$id = $self -> db -> util -> last_insert_id($table_name);
	}

	$table_name                 = 'email_people';
	$email                      = {};
	$$email{'email_address_id'} = $id;
	$$email{'person_id'}        = $$person{'id'};

	$self -> log(debug => "Saving email_person: $$email{'person_id'}");

	$self -> db -> util -> insert_hash($table_name, $email);
	$self -> db -> util -> last_insert_id($table_name);

} # End of save_email_address_for_person.

# -----------------------------------------------

sub update_email_address_type
{
	my($self, $creator_id, $address) = @_;

	$self -> log(debug => 'Entered update_email_address_type');

	$self -> db -> dbh -> do('update email_addresses set email_address_type_id = ? where id = ?', {}, $$address{'type_id'}, $$address{'address_id'});

} # End of update_email_address_type.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
