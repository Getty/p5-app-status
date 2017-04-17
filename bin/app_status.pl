#!/usr/bin/env perl
# PODNAME: app_status.pl
# ABSTRACT: Main Status Daemon with Interface

use strict;
use warnings;

use FindBin;
use lib $FindBin::Dir . "/../lib";

use App::Status;

$|=1;

exit App::Status->run;
