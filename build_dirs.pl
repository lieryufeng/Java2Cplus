#!/usr/bin/perl;

# package name must be equal to file name.
=pod windows
BEGIN {
	push @INC, "E:/self/program/perl/JavaToCplus_by_pm";
	push @INC, "E:/self/program/perl/JavaToCplus_by_pm/External";
}
=cut

#=pod ubuntu
BEGIN {
    unshift @INC, $ENV{"PWD"};
    unshift @INC, $ENV{"PWD"}."/External";
}
#=cut

use Cwd;
use strict;
use ToolBuildDirsFile;

my $ret = &main;

sub main
{
    &buildSourceFile;
    return 0;
}

sub buildSourceFile
{
	my $dirPath = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native";
	ToolBuildDirsFile::buildDirsAndSubsRecursive($dirPath);
}


