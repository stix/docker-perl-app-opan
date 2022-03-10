#!/usr/bin/env perl
use Mojo::Base -strict;

die "Please set environment variable OPAN_AUTH_TOKENS\n" unless $ENV{OPAN_AUTH_TOKENS};

system 'opan init' unless -d 'pans/upstream';

unshift @ARGV, 'opan';
exec @ARGV;
