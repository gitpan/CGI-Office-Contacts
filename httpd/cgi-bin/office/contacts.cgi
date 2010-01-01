#!/usr/bin/perl
#
# Name:
# contacts.cgi.
#
# Note:
# Need use lib here because CGI scripts don't have access to
# the PerlSwitches used in Apache's httpd.conf.
# Also, it saves having to install the module repeatedly during testing.

use lib '/home/ron/perl.modules/CGI-Office-Contacts/lib';
use strict;
use warnings;

use CGI;
use CGI::Application::Dispatch;

# ---------------------

my($cgi) = CGI -> new;

CGI::Application::Dispatch -> dispatch
(
 args_to_new => {QUERY => $cgi},
 debug       => 1,
 prefix      => 'CGI::Office::Contacts::Controller',
 table       =>
 [
  ''              => {app => 'Initialize', rm => 'display'},
  ':app'          => {rm => 'display'},
  ':app/:rm/:id?' => {},
 ],
);
