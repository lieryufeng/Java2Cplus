#!/usr/bin/perl;

package BuildMarco;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( buildMacros, buildMacro );
use strict;
use BuildElastosPath;

sub buildMacros {
    my $filePaths = shift;
    my @macros;
    foreach my $path (@$filePaths) {
        push @macros, &buildMacro($path);
    }
    return \@macros;
}

# such as:
# /home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/content/browser/FileA.h
# /home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/net/FileB.h
# /home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/ui/FileC.h
sub buildMacro {
    my $filePath = shift;
    my $idx = rindex($filePath, "/");
    my $fileName = substr($filePath, $idx + length("/"));
    $fileName =~ s/\.java/\.h/;
    $fileName =~ s/\.cpp/\.h/;
    $fileName =~ s/\./_/;
    my $macro = BuildElastosPath::buildElastosPath($filePath);
    $macro = "__".$macro."_".$fileName."__";
    $macro =~ tr/[a-z]/[A-Z]/;
    return $macro;
}

1;
