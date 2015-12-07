#!/usr/bin/perl;

package BuildElastosPath;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( buildElastosPath );
use strict;
use Util;

# such as:
# /home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui
# /home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/AAA.h
# return: Elastos_Droid_Core_webkit_ui_Gfx
sub buildElastosPath {
    my $filePath = shift;
    my $incIdx = rindex($filePath, "Core/");
    my $elastosPath = substr($filePath, $incIdx + length("Core/"));
    $elastosPath =~ s/inc\///g;
    $elastosPath =~ s/src\///g;
    $elastosPath =~ s/native\///g;
    $elastosPath =~ s/\/\w+\..*$//g;
    my @subs = split(/\//, $elastosPath);
	my $ucfirstSubs = Util::ucfirstArray(\@subs);
	$elastosPath = join "_", @$ucfirstSubs;
    return $elastosPath;
}

1;
