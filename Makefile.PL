use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'A web-based contacts manager',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Office-Contacts-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Office-Contacts',
	NAME      => 'CGI::Office::Contacts',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Carp                     => 0,
		CGI                      => 0,
		CGI::Application         => 0,
		CGI::Session             => 0,
		Config::Tiny             => 0,
		Data::Verifier           => 0,
		DateTime                 => 0,
		Date::Simple             => 0,
		DBD::Pg                  => 0,
		DBI                      => 0,
		DBIx::Admin::CreateTable => 0,
		FindBin::Real            => 0,
		HTML::Template           => 0,
		JSON::XS                 => 0,
		Log::Dispatch            => 0,
		Log::Dispatch::DBI       => 0,
		Moose                    => 0,
		namespace::autoclean     => 0,
		Path::Class              => 0,
		Sub::Exporter            => 0,
		Time::Elapsed            => 0,
	},
	VERSION_FROM => 'lib/CGI/Office/Contacts.pm',
);
