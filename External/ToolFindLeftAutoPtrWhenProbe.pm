#!/usr/bin/perl;

package ToolFindLeftAutoPtrWhenProbe;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use FileOperate;

sub findLeftAutoPtrWhenProbeWithPaths {
    my $paths = shift;
    print __LINE__." into findLeftAutoPtrWhenProbeWithPaths\n";
    my @empty = ();
    my $allFilesPath = FileOperate::readDirsAndExcepts($paths, \@empty, ".cpp");
	foreach my $filePath (@$allFilesPath) {
		&findLeftAutoPtrWhenProbeWithPath($filePath);
	}
}

sub findLeftAutoPtrWhenProbeWithPath {
    my $path = shift;
	my $fileLines = FileOperate::readFile($path);
    my $find = 0;
    my $line = "";
    my @matchInfos = ();
    for (my $idx=0; $idx<@$fileLines; ++$idx) {
    	$line = $fileLines->[$idx];
        if ($line !~ m/^\s*\/\// && $line =~ m/AutoPtr</ && $line =~ m/=/ && $line =~ m/Probe\(/) {
            $find = 1;
            my %info = ();
            $info{ "LineNumber" } = $idx + 1;
            $info{ "LineData" } = $line;
            push @matchInfos, \%info;
        }
    }

    if (1 eq $find) {
    	print __LINE__."\n";
		print __LINE__." find AutoPtr when Probe: \n$path\n";
		my $lineNumber = 0;
		my $lineData;
		foreach my $item (@matchInfos) {
			$lineNumber = $item->{ "LineNumber" };
			$lineData = $item->{ "LineData" };
			print __LINE__." [ln: $lineNumber]: $lineData";
		}
    }
}

1;
