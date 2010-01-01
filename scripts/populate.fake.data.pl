#!/usr/bin/perl
#
# Name:
#	populate.fake.data.pl.
#
# Description:
#	Populate some tables in the 'contacts' database.

use lib '/home/ron/perl.modules/CGI-Office-Contacts/lib';
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use CGI::Office::Contacts::Util::Create;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'verbose+',
) )
{
	pod2usage(1) if ($option{'help'});

	exit CGI::Office::Contacts::Util::Create -> new(%option) -> populate_fake_data;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

populate.fake.data.pl - Populate some tables in the 'contacts' database

=head1 SYNOPSIS

populate.fake.data.pl [options]

	Options:
	-help
	-verbose

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -verbose

Print progress messages.

If -v -v is used, print even more progress messages. In this case, the names
of all localities within states within countries (Australia, America) will be displayed.

=back

=head1 DESCRIPTION

populate.fake.data.pl populates some tables in the 'contacts' database.

=cut
