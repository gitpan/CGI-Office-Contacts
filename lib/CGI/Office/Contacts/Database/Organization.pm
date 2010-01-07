package CGI::Office::Contacts::Database::Organization;

use Moose;

extends 'CGI::Office::Contacts::Database::Base';

use namespace::autoclean;

our $VERSION = '1.01';

# --------------------------------------------------

sub add
{
	my($self, $organization) = @_;

	$self -> log(debug => 'Entered add');

	# Does an organizations with this name already exist?

	my($id) = $self -> get_organization_id_via_name($$organization{'name'} || '');

	my($result);

	if ($id)
	{
		$result = "The name '$$organization{'name'}' is already on file";
	}
	else
	{
		$result = "Added '$$organization{'name'}'";

		$self -> save_organization_transaction('add', $organization);
	}

	return $result;

} # End of add.

# -----------------------------------------------

sub delete
{
	my($self, $id, $input_name) = @_;

	$self -> log(debug => 'Entered delete');

	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from organizations where id = ?', {}, $id);
	$name     = $name ? $$name{'name'} : '';

	$self -> log(debug => "delete_organization. name result: " . $name ? $name : "N/A");

	my($result);

	if ($id == 1)
	{
		$result = "You cannot delete the special company called '-'";
	}
	elsif ($name && ($name eq $input_name) )
	{
		$self -> db -> dbh -> do("update organizations set broadcast_id = 3 where id = ?", {}, $id);

		$result = "Deleted '$input_name'";
	}
	else
	{
		$result = "'$input_name' not deleted: Not on file";
	}

	return $result;

} # End of delete.

# -----------------------------------------------

sub get_organization
{
	my($self, $user_id, $id) = @_;

	$self -> log(debug => 'Entered get_organization');

	my($name) = $self -> db -> dbh -> selectrow_hashref('select name from organizations where broadcast_id != 3 and id = ?', {}, $id);
	$name     = $name ? $$name{'name'} : '';

	return $name ? $self -> get_organizations($user_id, $name) : [];

} # End of get_organization.

# -----------------------------------------------

sub get_organization_id_via_name
{
	my($self, $name) = @_;

	$self -> log(debug => "Entered get_organization_id_via_name: $name");

	my($id) = $self -> db -> dbh -> selectrow_hashref('select id from organizations where broadcast_id != 3 and name = ?', {}, $name);

	return $id ? $$id{'id'} : 0;

} # End of get_organization_id_via_name.

# -----------------------------------------------

sub get_organization_via_id
{
	my($self, $id) = @_;

	$self -> log(debug => "Entered get_organization_via_id: $id");

	return $self -> db -> dbh -> selectrow_hashref("select * from organizations where id = ?", {}, $id);

} # End of get_organization_via_id.

# -----------------------------------------------

sub get_organizations
{
	my($self, $user_id, $name) = @_;

	$self -> log(debug => "Entered get_organizations: $name");

	my($broadcast)  = $self -> db -> util -> get_broadcasts;
	my($deleted_id) = $$broadcast{'(Hidden)'};
	my($org)        = $self -> db -> dbh -> selectall_arrayref("select * from organizations where upper(name) like ? order by name", {Slice => {} }, uc "%$name%");
	my($result)     = [];

	$self -> log(debug => "Org count: @{[scalar @$org]}");

	my($email);
	my($organization);
	my($people);
	my($skip);

	for $organization (@$org)
	{
		# Filter out the organizations whose broadcast status is no-one.

		$skip = 0;

		if ($$organization{'broadcast_id'} == $deleted_id)
		{
			$skip = 1;
		}

		# Let the user see records they created.

		if ( ($user_id > 0) && ($$organization{'creator_id'} == $user_id) )
		{
			$skip = 0;
		}

		if ($skip)
		{
			next;
		}

		$email  = $self -> get_organizations_emails_and_phones($$organization{'id'});
		$people = $self -> get_organizations_people($$organization{'id'});

		push @$result,
		{
			broadcast_id          => $$organization{'broadcast_id'},
			communication_type_id => $$organization{'communication_type_id'},
			email_phone           => $email,
			home_page             => $$organization{'home_page'},
			id                    => $$organization{'id'},
			name                  => $$organization{'name'},
			people                => $people,
			role_id               => $$organization{'role_id'},
		};
	}

	return $result;

} # End of get_organizations.

# -----------------------------------------------

sub get_organizations_emails_and_phones
{
	my($self, $id)  = @_;

	$self -> log(debug => "Entered get_organizations_emails_and_phones: $id");

	my($email_user) = $self -> db -> email_address -> get_email_address_id_via_organization($id);
	my($phone_user) = $self -> db -> phone_number -> get_phone_number_id_via_organization($id);
	my($max)        = ($#$email_user > $#$phone_user) ? $#$email_user : $#$phone_user;

	my(@data);
	my($email_address);
	my($i);
	my($phone_number);

	for $i (0 .. $max)
	{
		if ($i <= $#$email_user)
		{
			$email_address = $self -> db -> email_address -> get_email_address_via_id($$email_user[$i]{'email_address_id'});
		}
		else
		{
			$email_address = {address => '', type_id => 0, type_name => ''};
		}

		if ($i <= $#$phone_user)
		{
			$phone_number = $self -> db -> phone_number -> get_phone_number_via_id($$phone_user[$i]{'phone_number_id'});
		}
		else
		{
			$phone_number = {number => '', type_id => 0, type_name => ''};
		}

		push @data,
		{
			email =>
			{
				address   => $$email_address{'address'},
				type_id   => $$email_address{'type_id'},
				type_name => $$email_address{'type_name'},
			},
			phone =>
			{
				number    => $$phone_number{'number'},
				type_id   => $$phone_number{'type_id'},
				type_name => $$phone_number{'type_name'},
			},
		};
	}

	if ($#data < 0)
	{
		$data[0] =
		{
			email =>
			{
				address   => '',
				type_id   => 0,
				type_name => '',
			},
			phone =>
			{
				number    => '',
				type_id   => 0,
				type_name => '',
			},
		};
	}

	return [@data];

} # End of get_organizations_emails_and_phones.

# -----------------------------------------------

sub get_organizations_for_report
{
	my($self, $name) = @_;

	$self -> log(debug => 'Entered get_organizations_for_report');

	return $self -> db -> dbh -> selectall_arrayref('select * from organizations where name != ?', {Slice => {} }, $name) || [];

} # End of get_organizations_for_report.

# -----------------------------------------------

sub get_organizations_people
{
	my($self, $id)  = @_;

	$self -> log(debug => 'Entered get_organizations_people');

	my($occupation) = $self -> db -> occupation -> get_occupation_via_organization($id);

	my(@data);
	my($i);
	my($occ);

	for $i (0 .. $#$occupation)
	{
		$occ = $self -> db -> occupation -> get_occupation_via_id($$occupation[$i]);

		push @data,
		{
			occupation_id     => $$occupation[$i]{'id'},
			occupation_title  => $$occ{'title'},
			organization_id   => $$occ{'organization_id'},
			organization_name => $$occ{'organization_name'},
			person_id         => $$occ{'person_id'},
			person_name       => $$occ{'person_name'},
		};
	}

	@data = sort
	{
		$$a{'organization_name'} cmp $$b{'organization_name'} || $$a{'occupation_title'} cmp $$b{'occupation_title'}
	} @data;

	return [@data];

} # End of get_organizations_people.

# -----------------------------------------------

sub get_organizations_via_name_prefix
{
	my($self, $prefix) = @_;

	$self -> log(debug => "Entered get_organizations_via_name_prefix: $prefix");

	$prefix      = uc $prefix;
	my(%id2name) = $self -> db -> util -> select_map("select id, name from organizations where broadcast_id != 3 and upper(name) like '$prefix%'");

	my($id);
	my(@result);

	for $id (keys %id2name)
	{
		push @result, [$id2name{$id}, $id];
	}

	return [@result];

} # End of get_organizations_via_name_prefix.

# --------------------------------------------------

sub save_organization_record
{
	my($self, $context, $organization) = @_;

	$self -> log(debug => 'Entered save_organization_record');

	my($table_name) = 'organizations';
	my(@field)      = (qw/broadcast_id communication_type_id creator_id home_page name role_id/);
	my($data)       = {};

	for (@field)
	{
		$$data{$_} = $$organization{$_};
	}

	if ($context eq 'add')
	{
		$self -> db -> util -> insert_hash_get_id($table_name, $data);

		$$organization{'id'} = $$data{'id'} = $self -> db -> util -> last_insert_id($table_name);
	}
	else
	{
		my($s) = join(', ', map{"$_ = ?"} sort keys %$data);
		$s     = "update $table_name set $s where id = $$organization{'id'}";

	 	$self -> db -> dbh -> do($s, {}, map{$$data{$_} } sort keys %$data);
	}

} # End of save_organization_record.

# --------------------------------------------------

sub save_organization_transaction
{
	my($self, $context, $organization) = @_;

	$self -> log(debug => 'Entered save_organization_transaction');

	# Save organization.

	$self -> save_organization_record($context, $organization);

	# Save email addresses.

	my($email_organization) = $self -> db -> email_address -> get_email_address_id_via_organization($$organization{'id'});

	my($address);
	my($id);
	my(%old_address);

	for $id (@$email_organization)
	{
		$address                            = $self -> db -> email_address -> get_email_address_via_id($$id{'email_address_id'});
		$old_address{$$address{'address'} } =
		{                                                 # Table:
			organization_id  => $$id{'id'},               # email_organizations
			address_id       => $$id{'email_address_id'}, # email_addresses
			type_id          => $$address{'type_id'},     # email_address_types
			type_name        => $$address{'type_name'},   # email_address_types
		};
	}

	my($count);
	my(%new_address);
	my(%new_type);

	for $count (map{s/email_//; $_} grep{/email_\d/} sort keys %$organization)
	{
		$address = $$organization{"email_$count"};

		if ($address)
		{
			$new_address{$address} = $count;
			$new_type{$address}    = $$organization{"email_address_type_id_$count"};
		}
	}

	my(%address) = (%old_address, %new_address);

	for $address (keys %address)
	{
		if ($old_address{$address} && $new_address{$address})
		{
			# The email address type might have changed.

			if ($old_address{$address}{'type_id'} != $new_type{$address})
			{
				$old_address{$address}{'type_id'} = $new_type{$address};

				$self -> db -> email_address -> update_email_address_type($$organization{'creator_id'}, $old_address{$address});
			}
		}
		elsif ($old_address{$address}) # And ! new address.
		{
			# Address has vanished, so delete old address.

			$self -> db -> email_address -> delete_email_address_organization($$organization{'creator_id'}, $old_address{$address}{'organization_id'});
		}
		else # ! old address, just new one.
		{
			# Address has appeared, so add new address.

			$self -> db -> email_address -> save_email_address_for_organization($context, $organization, $new_address{$address});
		}
	}

	# Save phone numbers.

	my($phone_organization) = $self -> db -> phone_number -> get_phone_number_id_via_organization($$organization{'id'});

	my($number);
	my(%old_number);

	for $id (@$phone_organization)
	{
		$number                          = $self -> db -> phone_number -> get_phone_number_via_id($$id{'phone_number_id'});
		$old_number{$$number{'number'} } =
		{                                               # Table:
			organization_id => $$id{'id'},              # phone_organizations
			number_id       => $$id{'phone_number_id'}, # phone_numbers
			type_id         => $$number{'type_id'},     # phone_number_types
			type_name       => $$number{'type_name'},   # phone_number_types
		};
	}

	%new_type = ();

	my(%new_number);

	for $count (map{s/phone_//; $_} grep{/phone_\d/} sort keys %$organization)
	{
		$number = $$organization{"phone_$count"};

		if ($number)
		{
			$new_number{$number} = $count;
			$new_type{$number}   = $$organization{"phone_number_type_id_$count"};
		}
	}

	my(%number) = (%old_number, %new_number);

	for $number (keys %number)
	{
		if ($old_number{$number} && $new_number{$number})
		{
			# The phone number type might have changed.

			if ($old_number{$number}{'type_id'} != $new_type{$number})
			{
				$old_number{$number}{'type_id'} = $new_type{$number};

				$self -> db -> phone_number -> update_phone_number_type($$organization{'creator_id'}, $old_number{$number});
			}
		}
		elsif ($old_number{$number}) # And ! new number.
		{
			# Number has vanished, so delete old number.

			$self -> db -> phone_number -> delete_phone_number_organization($$organization{'creator_id'}, $old_number{$number}{'organization_id'});
		}
		else # ! old number, just new one.
		{
			# Number has appeared, so add new number.

			$self -> db -> phone_number -> save_phone_number_for_organization($context, $organization, $new_number{$number});
		}
	}

} # End of save_organization_transaction.

# --------------------------------------------------

sub update
{
	my($self, $organization) = @_;

	$self -> log(debug => 'Entered update');

	my($result);

	# Special code for id == 1.

	if ($$organization{'id'} <= 1)
	{
		$result = "You cannot update the special company called '-'";
	}
	else
	{
		$self -> save_organization_transaction('update', $organization);

		$result = "Updated '$$organization{'name'}'";
	}

	return $result;

} # End of update.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
