package CGI::Office::Contacts::View::Occupation;

use Moose;

extends 'CGI::Office::Contacts::View::Base';

use namespace::autoclean;

our $VERSION = '1.00';

# -----------------------------------------------

sub build_add_occupation_template
{
	my($self) = @_;

	$self -> log(debug => 'Entered build_occupation_template');

	my($form_action) = ${$self -> config}{'form_action'};

	# Phase 1: Occupation autocomplete.

	my($occupation_autocomplete) = $self -> load_tmpl('autocomplete.tmpl');

	$occupation_autocomplete -> param(context => 'occupation');

	my($occupation_js) = $self -> load_tmpl('autocomplete.js');

	$occupation_js -> param(context     => 'occupation');
	$occupation_js -> param(form_action => $form_action);
	$occupation_js -> param(sid         => $self -> session -> id);

	$occupation_js = $occupation_js -> output;

	# Phase 2: Organization autocomplete.

	my($organization_autocomplete) = $self -> load_tmpl('autocomplete.tmpl');

	$organization_autocomplete -> param(context => 'organization');

	my($organization_js) = $self -> load_tmpl('autocomplete.js');

	$organization_js -> param(context     => 'organization');
	$organization_js -> param(form_action => $form_action);
	$organization_js -> param(sid         => $self -> session -> id);

	$organization_js = $organization_js -> output;

	# Phase 3: Person autocomplete.

	my($person_autocomplete) = $self -> load_tmpl('autocomplete.tmpl');

	$person_autocomplete -> param(context => 'person');

	my($person_js) = $self -> load_tmpl('autocomplete.js');

	$person_js -> param(context     => 'person');
	$person_js -> param(form_action => $form_action);
	$person_js -> param(sid         => $self -> session -> sid);

	$person_js = $person_js -> output;

	# Phase 4: The 'add' form.

	my($update_template) = $self -> load_tmpl('update.occupation.tmpl');

	$update_template -> param(context      => 'add');
	$update_template -> param(go           => 'Add');
	$update_template -> param(name         => 'New occupation');
	$update_template -> param(occupation   => $occupation_autocomplete -> output);
	$update_template -> param(organization => $organization_autocomplete -> output);
	$update_template -> param(person       => $person_autocomplete -> output);
	$update_template -> param(reset_button => 1);
	$update_template -> param(sid          => $self -> session -> id);

	$update_template = $update_template -> output;
	$update_template =~ s/\n//g;

	# Phase 5: The Javascript for the 'add' form.

	my($update_js) = $self -> load_tmpl('update.occupation.js');

	$update_js -> param(context     => 'add');
	$update_js -> param(form_action => $form_action);

	$update_js = $update_js -> output;

	return ($update_template, $update_js, $occupation_js, $organization_js, $person_js);

} # End of build_add_occupation_template.

# -----------------------------------------------

sub report_add
{
	my($self, $result) = @_;

	$self -> log(debug => 'Entered add_occupation_report');

	my($msgs)     = $result -> msgs;
	my(%prompt)   = map{my($s) = $_; $s =~ s/^field_//; $s =~ tr/_/ /; ($_ => ucfirst $s)} keys %$msgs;
	my($template) = $self -> load_tmpl('update.report.tmpl');
	my($error)    = $result -> has_invalid || $result -> has_missing;

	$template -> param(error => $$msgs{'error'});

	if ($error)
	{
		my($msg);
		my(@msg);

		for $msg (sort keys %$msgs)
		{
			if ($msg =~ /^field_/)
			{
				push @msg, qq|$prompt{$msg}: $$msgs{$msg}|;
			}
		}

		$template -> param(tr_loop => [map{ {td => $_} } @msg]);
	}
	else
	{
		# Use scalar context to retrieve a hash ref.

		my $occupation = $result -> valid;

		# Now we have to combine the original data from the CGI form
		# with the ids returned by the validation process.

		my($id);
		my($new_key, %new_data);
		my($old_key);

		for $old_key (keys %$occupation)
		{
			$id = $$occupation{$old_key};

			# If the data passed validation, $old_key will be one of:
			# o occupation_ac_name
			# o organization_ac_name
			# o person_ac_name
			# and the value will be an id. This goes into the new_data,
			# but under the name of (occupation_title|organization|person)_id.

			if ($id)
			{
				($new_key = $old_key) =~ s/(.+)_ac_name/$1/;

				if ($new_key eq 'occupation')
				{
					$new_key = 'occupation_title_id';
				}
				else
				{
					$new_key = "${new_key}_id";
				}

				$new_data{$new_key} = $id;
			}
			else
			{
				# We can only get here with a new occupation title.
				# So we put it in the occupation_titles table.

				$id = $self -> db -> occupation -> save_occupation_title($self -> param($old_key), $self -> param('user_id') );
				$new_data{'occupation_title_id'} = $id;
			}
		}

		# Force the user_id into the person's record, so it is available elsewhere.
		# Note: This is the user_id of the person logged on.

		$new_data{'creator_id'} = $self -> param('user_id');

		$self -> log(debug => '-' x 50);
		$self -> log(debug => "Adding occupation:...");
		$self -> log(debug => "$_ => $new_data{$_}") for sort keys %new_data;
		$self -> log(debug => '-' x 50);

		$self -> db -> occupation -> add(\%new_data);

		$template -> param(message => "Added '" . $self -> param('occupation_ac_name') . "'");
	}

	return $template -> output;

} # End of report_add.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
