#!/usr/bin/perl;

package ToolModifyStringToConst;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use FileOperate;

sub modifyStringWithPaths {
    my $paths = shift;
    foreach (@$paths) {
    	print __LINE__." path: $_\n";
		&modifyStringWithPath($_);
	}
}

sub modifyStringWithPath {
    my $path = shift;
	my $fileLines = FileOperate::readFile($path);
    my $needModify = 0;
    my $stringIdx = 0;
    my $sub0 = "";
    my $sub1 = "";
    my $line = "";
    for (my $idx=0; $idx<@$fileLines; ++$idx) {
    	$line = $fileLines->[$idx];
        if ($line =~ m/^\s*\/\*\s*\[\s*in\s*\]\s*\*\/\s*String /) {
            $needModify = 1;
			$stringIdx = index($line, "String");
			$sub0 = substr($line, 0, $stringIdx);
			$sub1 = substr($line, $stringIdx + length("String"));
			$line = $sub0."const String&".$sub1;
			$fileLines->[$idx] = $line;
        }
    }

    if (1 eq $needModify) {
		print __LINE__." String need trans: $path\n";
		FileOperate::writeFile($path, $fileLines);
    }
}

1;

