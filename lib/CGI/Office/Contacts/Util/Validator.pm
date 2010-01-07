package CGI::Office::Contacts::Util::Validator;

use Data::Verifier;

use Moose;

has config => (is => 'ro', isa => 'HashRef', required => 1);
has db     => (is => 'ro', isa => 'CGI::Office::Contacts::Database', required => 1);
has query  => (is => 'ro', isa => 'Any', required => 1);

use namespace::autoclean;

our $VERSION = '1.01';

# -----------------------------------------------

sub clean_user_data
{
	my($data, $max_length) = @_;
	$max_length  ||= 250;
	my($integer) = 0;
	$data = '' if (! defined($data) || (length($data) == 0) || (length($data) > $max_length) );
	#$data = '' if ($data =~ /<script\s*>.+<\s*\/?\s*script\s*>/i);	# http://www.perl.com/pub/a/2002/02/20/css.html.
	$data = '' if ($data =~ /<(.+)\s*>.*<\s*\/?\s*\1\s*>/i);		# Ditto, but much more strict.
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	$data = 0 if ($integer && (! $data || ($data !~ /^[0-9]+$/) ) );

	return $data;

}	# End of clean_user_data.

# -----------------------------------------------

sub log
{
	my($self, @param) = @_;

	$self -> db -> log(@param);

} # End of log.

# --------------------------------------------------

sub notes
{
	my($self) = @_;

	$self -> log(debug => 'Entered notes');

	my($max_note_length) = ${$self -> config}{'max_note_length'};
	my($verifier)        = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			action =>
			{
				post_check => sub {my($a) = shift -> get_value('action'); return $a == 1 || $a == 2},
				required => 1,
				type     => 'Int',
			},
			note =>
			{
				# We can't call clean_user_data as a filter here,
				# because we need to pass in the max length,
				# and we can't call it as a post_check, since it
				# returns the clean data, not an error flag.
				max_length => $max_note_length,
				min_length => 1,
				required   => 1,
				type       => 'Str',
			},
			sid =>
			{
				required => 1,
				type     => 'Str',
			},
			submit_notes_add =>
			{
				required => 0,
				type     => 'Str',
			},
			target_id =>
			{
				required => 1,
				type     => 'Int',
			},
		},
	);

	return $verifier -> verify({$self -> query -> Vars});

} # End of notes.

# --------------------------------------------------

sub organization
{
	my($self) = @_;

	$self -> log(debug => 'Entered organization');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			broadcast_id =>
			{
				post_check => sub {my $id = shift -> get_value('broadcast_id'); return $self -> db -> util -> validate_broadcast($id)},
				required   => 1,
				type       => 'Int',
			},
			communication_type_id =>
			{
				post_check => sub {my $id = shift -> get_value('communication_type_id'); return $self -> db -> util -> validate_communication_type($id)},
				required   => 1,
				type       => 'Int',
			},
			email_1 =>
			{
				dependent =>
				{
					email_address_type_id_1 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_1'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			email_2 =>
			{
				dependent =>
				{
					email_address_type_id_2 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_2'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			email_3 =>
			{
				dependent =>
				{
					email_address_type_id_3 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_3'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			email_4 =>
			{
				dependent =>
				{
					email_address_type_id_4 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_4'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			home_page =>
			{
				required => 0,
				type     => 'Str',
			},
			name =>
			{
				max_length => 250,
				required   => 1,
				type       => 'Str',
			},
			phone_1 =>
			{
				dependent =>
				{
					phone_number_type_id_1 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_1'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			phone_2 =>
			{
				dependent =>
				{
					phone_number_type_id_2 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_2'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			phone_3 =>
			{
				dependent =>
				{
					phone_number_type_id_3 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_3'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			phone_4 =>
			{
				dependent =>
				{
					phone_number_type_id_4 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_4'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			role_id =>
			{
				post_check => sub {my $id = shift -> get_value('role_id'); return $self -> db -> util -> validate_role($id)},
				required   => 1,
				type       => 'Int',
			},
			submit_organization_add =>
			{
				required => 0,
				type     => 'Str',
			},
			submit_organization_delete =>
			{
				required => 0,
				type     => 'Str',
			},
			submit_organization_update =>
			{
				required => 0,
				type     => 'Str',
			},
		},
	);

	return $verifier -> verify({$self -> query -> Vars});

} # End of organization.

# --------------------------------------------------

sub person
{
	my($self) = @_;

	$self -> log(debug => 'Entered person');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			broadcast_id =>
			{
				post_check => sub {my $id = shift -> get_value('broadcast_id'); return $self -> db -> util -> validate_broadcast($id)},
				required   => 1,
				type       => 'Int',
			},
			communication_type_id =>
			{
				post_check => sub {my $id = shift -> get_value('communication_type_id'); return $self -> db -> util -> validate_communication_type($id)},
				required   => 1,
				type       => 'Int',
			},
			email_1 =>
			{
				dependent =>
				{
					email_address_type_id_1 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_1'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required  => 0,
				type      => 'Str',
			},
			email_2 =>
			{
				dependent =>
				{
					email_address_type_id_2 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_2'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			email_3 =>
			{
				dependent =>
				{
					email_address_type_id_3 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_3'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			email_4 =>
			{
				dependent =>
				{
					email_address_type_id_4 =>
					{
						post_check => sub {my $id = shift -> get_value('email_address_type_id_4'); return $self -> db -> util -> validate_email_address_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			gender_id =>
			{
				post_check => sub {my $id = shift -> get_value('gender_id'); return $self -> db -> util -> validate_gender($id)},
				required   => 1,
				type       => 'Int',
			},
			given_names =>
			{
				max_length => 250,
				required   => 1,
				type       => 'Str',
			},
			home_page =>
			{
				required => 0,
				type     => 'Str',
			},
			phone_1 =>
			{
				dependent =>
				{
					phone_number_type_id_1 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_1'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			phone_2 =>
			{
				dependent =>
				{
					phone_number_type_id_2 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_2'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			phone_3 =>
			{
				dependent =>
				{
					phone_number_type_id_3 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_3'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			phone_4 =>
			{
				dependent =>
				{
					phone_number_type_id_4 =>
					{
						post_check => sub {my $id = shift -> get_value('phone_number_type_id_4'); return $self -> db -> util -> validate_phone_number_type($id)},
						required   => 1,
						type       => 'Int',
					}
				},
				required => 0,
				type     => 'Str',
			},
			role_id =>
			{
				post_check => sub {my $id = shift -> get_value('role_id'); return $self -> db -> util -> validate_role($id)},
				required   => 1,
				type       => 'Int',
			},
			submit_person_add =>
			{
				required => 0,
				type     => 'Str',
			},
			submit_person_delete =>
			{
				required => 0,
				type     => 'Str',
			},
			submit_person_update =>
			{
				required => 0,
				type     => 'Str',
			},
			surname =>
			{
				max_length => 250,
				required   => 1,
				type       => 'Str',
			},
			title_id =>
			{
				post_check => sub {my $id = shift -> get_value('title_id'); return $self -> db -> util -> validate_title($id)},
				required   => 1,
				type       => 'Int',
			},
		},
	);

	return $verifier -> verify({$self -> query -> Vars});

} # End of person.

# --------------------------------------------------

sub report
{
	my($self) = @_;

	$self -> log(debug => 'Entered report');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			broadcast_id =>
			{
				post_check => sub {my $id = shift -> get_value('broadcast_id'); return $self -> db -> util -> validate_broadcast($id)},
				required   => 1,
				type       => 'Int',
			},
			communication_type_id =>
			{
				post_check => sub {my $id = shift -> get_value('communication_type_id'); return $self -> db -> util -> validate_communication_type($id)},
				required   => 1,
				type       => 'Int',
			},
			date_range =>
			{
				required => 0,
				type     => 'Str',
			},
			gender_id =>
			{
				post_check => sub {my $id = shift -> get_value('gender_id'); return $self -> db -> util -> validate_gender($id)},
				required   => 1,
				type       => 'Int',
			},
			ignore_broadcast =>
			{
				post_check => sub {return shift -> get_value('ignore_broadcast') ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			ignore_communication_type =>
			{
				post_check => sub {return shift -> get_value('ignore_communication_type') ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			ignore_gender =>
			{
				post_check => sub {return shift -> get_value('ignore_gender') ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			ignore_role =>
			{
				post_check => sub {return shift -> get_value('ignore_role') ? 1 : 0},
				required   => 0,
				type       => 'Int',
			},
			report_id =>
			{
				post_check => sub {my $id = shift -> get_value('report_id'); return $self -> db -> util -> validate_report($id)},
				required   => 1,
				type       => 'Int',
			},
			report_entity_id =>
			{
				post_check => sub {my $id = shift -> get_value('report_entity_id'); return $self -> db -> util -> validate_report_entity($id)},
				required   => 1,
				type       => 'Int',
			},
			role_id =>
			{
				post_check => sub {my $id = shift -> get_value('role_id'); return $self -> db -> util -> validate_role($id)},
				required   => 1,
				type       => 'Int',
			},
		},
	);

	return $verifier -> verify({$self -> query -> Vars});

} # End of report.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

From http://search.cpan.org/~flora/Moose-0.93/lib/Moose/Manual/Types.pod

  Any
  Item
      Bool
      Maybe[`a]
      Undef
      Defined
          Value
              Str
                Num
                    Int
                ClassName
                RoleName
          Ref
              ScalarRef
              ArrayRef[`a]
              HashRef[`a]
              CodeRef
              RegexpRef
              GlobRef
                FileHandle
              Object

=cut
