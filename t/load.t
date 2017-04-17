#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  App::Status
  App::Status::Web
)) {
  use_ok($_);
}

done_testing;

