#!/usr/bin/perl;

package BuildIncludes;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;


sub buildIncludes
{
    my $root = shift;
    my @includes = ();
	push @includes, "#include \"elastos/droid/ext/frameworkext.h\"\n";
    return \@includes;
}



1;
