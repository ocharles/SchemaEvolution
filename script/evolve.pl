#!/usr/bin/perl
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use SchemaEvolution;

my $app = SchemaEvolution->new_with_options;
$app->run
