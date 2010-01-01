package CGI::Office::Contacts::Database::PhoneNumber;

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

sub delete_phone_number_organization
{
	my($self, $creator_id, $id) = @_;

	$self -> log(debug => 'Entered delete_phone_number_organization');

	$self -> db -> dbh -> do('delete from phone_organizations where id = ?', {}, $id);

} # End of delete_phone_number_organization.

# -----------------------------------------------

sub delete_phone_number_person
{
	my($self, $creator_id, $id) = @_;

	$self -> log(debug => 'Entered delete_phone_number_people');

	$self -> db -> dbh -> do('delete from phone_people where id = ?', {}, $id);

} # End of delete_phone_number_people.

# -----------------------------------------------

sub get_phone_number_id_via_number
{
	my($self, $number) = @_;

	$self -> log(debug => "Entered get_phone_number_id_via_number: $number");

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from phone_numbers where number = ?', {}, $number);
	$id     = $id ? $$id{'id'} : 0;

	return $id;

} # End of get_phone_number_id_via_number.

# -----------------------------------------------

sub get_phone_number_id_via_organization
{
	my($self, $organization_id) = @_;

	$self -> log(debug => "Entered get_phone_number_id_via_organization: $organization_id");

	return $self -> db -> dbh -> selectall_arrayref('select id, phone_number_id from phone_organizations where organization_id = ?', {Slice => {} }, $organization_id) || [];

} # End of get_phone_number_id_via_organization.

# -----------------------------------------------

sub get_phone_number_id_via_person
{
	my($self, $person_id) = @_;

	$self -> log(debug => "Entered get_phone_number_id_via_person: $person_id");

	return $self -> db -> dbh -> selectall_arrayref('select id, phone_number_id from phone_people where person_id = ?', {Slice => {} }, $person_id) || [];

} # End of get_phone_number_id_via_person.

# -----------------------------------------------

sub get_phone_number_type_id_via_name
{
	my($self, $name) = @_;

	$self -> log(debug => "Entered get_phone_number_type_id_via_name: $name");

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from phone_number_types where name = ?', {}, $name);
	$id     = $id ? $$id{'id'} : 0;

	return $id;

} # End of get_phone_number_id_type_via_name.

# -----------------------------------------------

sub get_phone_number_type_name_via_id
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_phone_number_type_name_via_id: $id");

	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from phone_number_types where id = ?', {}, $id);
	$name     = $name ? $$name{'name'} : '';

	return $name;

} # End of get_phone_number_id_name_via_id.

# -----------------------------------------------

sub get_phone_number_via_id
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_phone_number_via_id: $id");

	my($number) = $self -> db -> dbh -> selectrow_hashref('select number, phone_number_type_id from phone_numbers where id = ?', {}, $id);
	my($name)   = $self -> get_phone_number_type_name_via_id($$number{'phone_number_type_id'});

	return
	{
		number    => $$number{'number'},
		type_id   => $$number{'phone_number_type_id'},
		type_name => $name,
	};

} # End of get_phone_number_via_id.

# --------------------------------------------------

sub save_phone_number_for_organization
{
	my($self, $context, $organization, $count) = @_;

	$self -> log(debug => 'Entered save_phone_number_for_organization');

	my($table_name)                 = 'phone_numbers';
	my($phone)                      = {};
	$$phone{'number'}               = $$organization{"phone_$count"};
	$$phone{'phone_number_type_id'} = $$organization{"phone_number_type_id_$count"};
	my($id)                         = $self -> get_phone_number_id_via_number($$phone{'number'});

	if ($id == 0)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $phone);

		$id = $self -> db -> util -> last_insert_id($table_name);
	}

	$table_name                = 'phone_organizations';
	$phone                     = {};
	$$phone{'organization_id'} = $$organization{'id'};
	$$phone{'phone_number_id'} = $id;

	$self -> db -> util -> insert_hash_get_id($table_name, $phone);
	$self -> db -> util -> last_insert_id($table_name);

} # End of save_phone_number_for_organization.

# --------------------------------------------------

sub save_phone_number_for_person
{
	my($self, $context, $person, $count) = @_;

	$self -> log(debug => 'Entered save_phone_number_for_person');

	my($table_name)                 = 'phone_numbers';
	my($phone)                      = {};
	$$phone{'number'}               = $$person{"phone_$count"};
	$$phone{'phone_number_type_id'} = $$person{"phone_number_type_id_$count"};
	my($id)                         = $self -> get_phone_number_id_via_number($$phone{'number'});

	$self -> log(debug => "Saving phone_number: $$phone{'number'}");

	if ($id == 0)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $phone);

		$id = $self -> db -> util -> last_insert_id($table_name);
	}

	$table_name                = 'phone_people';
	$phone                     = {};
	$$phone{'person_id'}       = $$person{'id'};
	$$phone{'phone_number_id'} = $id;

	$self -> log(debug => "Saving phone_person: $$phone{'person_id'}");

	$self -> db -> util -> insert_hash_get_id($table_name, $phone);
	$self -> db -> util -> last_insert_id($table_name);

} # End of save_phone_number_for_person.

# -----------------------------------------------

sub update_phone_number_type
{
	my($self, $creator_id, $number) = @_;

	$self -> log(debug => 'Entered update_phone_number_type');

	$self -> db -> dbh -> do('update phone_numbers set phone_number_type_id = ? where id = ?', {}, $$number{'type_id'}, $$number{'number_id'});

} # End of update_phone_number_type.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
