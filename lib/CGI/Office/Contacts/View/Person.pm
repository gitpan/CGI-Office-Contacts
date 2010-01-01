package CGI::Office::Contacts::View::Person;

use Moose;

extends 'CGI::Office::Contacts::View::Base';

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

sub build_add_person_html
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_add_person_html');

	my($html) = $self -> load_tmpl('update.person.tmpl');

	$html -> param(action                => 101); # Add.
	$html -> param(broadcasts            => $self -> build_select('broadcasts') );
	$html -> param(communication_types   => $self -> build_select('communication_types') );
	$html -> param(context               => 'add');
	$html -> param(email_address_types_1 => $self -> build_select('email_address_types', '_1') );
	$html -> param(email_address_types_2 => $self -> build_select('email_address_types', '_2') );
	$html -> param(email_address_types_3 => $self -> build_select('email_address_types', '_3') );
	$html -> param(email_address_types_4 => $self -> build_select('email_address_types', '_4') );
	$html -> param(genders               => $self -> build_select('genders') );
	$html -> param(go                    => 'Add');
	$html -> param(phone_number_types_1  => $self -> build_select('phone_number_types', '_1') );
	$html -> param(phone_number_types_2  => $self -> build_select('phone_number_types', '_2') );
	$html -> param(phone_number_types_3  => $self -> build_select('phone_number_types', '_3') );
	$html -> param(phone_number_types_4  => $self -> build_select('phone_number_types', '_4') );
	$html -> param(reset_button          => 1);
	$html -> param(result                => 'New person');
	$html -> param(roles                 => $self -> build_select('roles') );
	$html -> param(sid                   => $self -> session -> id);
	$html -> param(target_id             => 0);
	$html -> param(titles                => $self -> build_select('titles', '', 3) ); # Ms to match Gender == 1.

	# Make YUI happy by turning the HTML into 1 long line.

	$html = $html -> output;
	$html =~ s/\n//g;

	return $html;

} # End of build_add_person_html.

# -----------------------------------------------

sub build_add_person_js
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_add_person_js');

	my($js) = $self -> load_tmpl('update.person.js');

	$js -> param(context     => 'add');
	$js -> param(form_action => ${$self -> config}{'form_action'});

	return $js -> output;

} # End of build_add_person_js.

# -----------------------------------------------

sub build_update_person_html
{
	my($self, $target_id, $person) = @_;

	$self -> log(debug => 'Entered build_update_person_html');

	my($template) = $self -> load_tmpl('update.person.tmpl');

	$template -> param(action              => 105); # Update.
	$template -> param(broadcasts          => $self -> build_select('broadcasts', '', $$person{'broadcast_id'}) );
	$template -> param(communication_types => $self -> build_select('communication_types', '', $$person{'communication_type_id'}) );
	$template -> param(context             => 'update');
	$template -> param(genders             => $self -> build_select('genders', '', $$person{'gender_id'}) );
	$template -> param(given_names         => $$person{'given_names'});
	$template -> param(go                  => 'Update');
	$template -> param(home_page           => $$person{'home_page'});
	$template -> param(preferred_name      => $$person{'preferred_name'});
	$template -> param(reset_button        => 0);
	$template -> param(result              => $$person{'name'});
	$template -> param(roles               => $self -> build_select('roles', '', $$person{'role_id'}) );
	$template -> param(surname             => $$person{'surname'});
	$template -> param(sid                 => $self -> session -> id);
	$template -> param(target_id           => $target_id);
	$template -> param(titles              => $self -> build_select('titles', '', $$person{'title_id'}) );

	my($email);
	my($field);
	my($i);
	my($phone);
	my($type);

	# Hard-code 0 .. 3 email addresses and phone numbers.
	# If we don't then less than 3 means the type menus don't appear,
	# in which case we'd need a separate loop just to display them.

	for $i (0 .. 3)
	{
		$email = $i <= $#{$$person{'email_phone'} } ? $$person{'email_phone'}[$i]{'email'} : {};
		$phone = $i <= $#{$$person{'email_phone'} } ? $$person{'email_phone'}[$i]{'phone'} : {};
		$field = 'email_' . ($i + 1);
		$type  = 'email_address_types_' . ($i + 1);

		if ($$email{'address'})
		{
			$template -> param($field => $$email{'address'});
		}

		$template -> param($type => $self -> build_select('email_address_types', '_' . ($i + 1), $$email{'type_id'} || 1) );

		$field = 'phone_' . ($i + 1);
		$type  = 'phone_number_types_' . ($i + 1);

		if ($$phone{'number'})
		{
			$template -> param($field => $$phone{'number'});
		}

		$template -> param($type => $self -> build_select('phone_number_types', '_' . ($i + 1), $$phone{'type_id'} || 1) );
	}

	my($link);
	my(@occupation);

	for $field (@{$$person{'occupation'} })
	{
		if ($$field{'organization_name'} eq '-')
		{
			$link = '-';
		}
		else
		{
			$link = qq|<a href="#tab1" onClick="display_organization($$field{'organization_id'})">$$field{'organization_name'}</a>|;
		}

		push @occupation,
		{
			occupation_id => $$field{'occupation_id'},
			name          => $link,
			title         => $$field{'occupation_title'},
		};
	}

	$template -> param(occupation_loop => [@occupation]);

	# Make YUI happy by turning the HTML into 1 long line.

	$template = $template -> output;
	$template =~ s/\n//g;

	return $template;

} # End of build_update_person_html.

# -----------------------------------------------

sub build_update_person_js
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_update_person_js');

	my($js)   = $self -> load_tmpl('update.person.js');

	$js -> param(context     => 'update');
	$js -> param(form_action => ${$self -> config}{'form_action'});

	return $js -> output;

} # End of build_update_person_js.

# -----------------------------------------------

sub format_search_result
{
	my($self, $name, $people) = @_;

	$self -> log(debug => 'Entered format_search_result');

	my(@row);

	if ($name && ($#$people >= 0) )
	{
		my($email);
		my($i);
		my($person, $phone);

		for $person (@$people)
		{
			$name = $$person{'name'};

			for $i (0 .. $#{$$person{'email_phone'} })
			{
				$email  = $$person{'email_phone'}[$i]{'email'};
				$phone  = $$person{'email_phone'}[$i]{'phone'};

				push @row,
				{
					email      => qq|<a href="mailto:$$email{'address'}">$$email{'address'}</a>|,
					email_type => $$email{'type_name'},
					id         => $$person{'id'},
					name       => $name ? qq|<a href="#tab1" onClick="display_person($$person{'id'})">$name</a>| : '',
					phone      => $$phone{'number'},
					phone_type => $$phone{'type_name'},
					role       => $name ? $self -> db -> util -> get_role_via_id($$person{'role_id'}) : '',
				};

				# Blanking out the name means it is not repeated in the output (HTML) table.

				$name = '';
			}
		}
	}

	return [@row];

} # End of format_search_result.

# -----------------------------------------------

sub report_add
{
	my($self, $user_id, $result) = @_;

	$self -> log(debug => 'Entered report_add');

	my($template) = $self -> load_tmpl('update.report.tmpl');

	if ($result -> success)
	{
		# Force the user_id into the person's record, so it is available elsewhere.
		# Note: This is the user_id of the person logged on.

		my($person)            = {};
		$$person{'creator_id'} = $user_id;

		for my $field_name ($result -> valids)
		{
			$$person{$field_name} = $result -> get_value($field_name) || '';
		}

		# Force the Name to match "Given name(s)<1 space>Surname".
		# There is no 'if' because there is no input field for 'name'.

		$$person{'name'} = "$$person{'given_names'} $$person{'surname'}";

		# Force an empty Preferred name to match the Given name(s).

		if (! $$person{'preferred_name'})
		{
			$$person{'preferred_name'} = $$person{'given_names'};
		}

		$self -> log(debug => '-' x 50);
		$self -> log(debug => "Adding person $$person{'given_names'} $$person{'surname'}...");
		$self -> log(debug => "$_ => $$person{$_}") for sort keys %$person;
		$self -> log(debug => '-' x 50);

		$template -> param(message => $self -> db -> person -> add($person) );
	}
	else
	{
		$self -> db -> util -> build_error_report($result, $template);

		$template -> param(message => 'Failed to add person');
	}

	return $template -> output;

} # End of report_add.

# -----------------------------------------------

sub report_update
{
	my($self, $user_id, $id, $result) = @_;

	$self -> log(debug => 'Entered update_person_report');

	my($template) = $self -> load_tmpl('update.report.tmpl');

	if ($result -> success)
	{
		# Force the user_id into the person's record, so it is available elsewhere.
		# Note: This is the user_id of the person logged on.

		my($person)            = {};
		$$person{'creator_id'} = $user_id;

		for my $field_name ($result -> valids)
		{
			$$person{$field_name} = $result -> get_value($field_name) || '';
		}

		# Force the person's id to be the id from the form.

		$$person{'id'} = $id;

		# Force the Name to match "Given name(s)<1 space>Surname".
		# There is no 'if' because there is no input field for 'name'.

		$$person{'name'} = "$$person{'given_names'} $$person{'surname'}";

		# Force an empty Preferred name to match the Given name(s).

		if (! $$person{'preferred_name'})
		{
			$$person{'preferred_name'} = $$person{'given_names'};
		}

		$self -> log(debug => '-' x 50);
		$self -> log(debug => "Updating person $$person{'name'}...");
		$self -> log(debug => "$_ => $$person{$_}") for sort keys %$person;
		$self -> log(debug => '-' x 50);

		$template -> param(message => $self -> db -> person -> update($person) );
	}
	else
	{
		$self -> db -> util -> build_error_report($result, $template);

		$template -> param(message => 'Failed to add person');
	}

	return $template -> output;

} # End of report_update.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
