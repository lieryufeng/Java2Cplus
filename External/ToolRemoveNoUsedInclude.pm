#!/usr/bin/perl;

package ToolRemoveNoUsedInclude;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use FileOperate;

sub removeNoUsedIncludeWithPaths {
    my $paths = shift;
    foreach (@$paths) {
    	print __LINE__." path: $_\n";
		&removeNoUsedIncludeWithPath($_);
	}
}

sub removeNoUsedIncludeWithPath {
    my $path = shift;
	my $fileLines = FileOperate::readFile($path);
    my $needModify = 0;
    my $stringIdx = 0;
    my $sub0 = "";
    my $sub1 = "";
    my $line = "";
    my @newFileLines = ();
    for (my $idx=0; $idx<@$fileLines; ++$idx) {
    	$line = $fileLines->[$idx];
        if ($line !~ m/^\/\/\s*#include /) {
            $needModify = 1;
			push @newFileLines, $line;
        }
    }
    
    my $firstInclude = -1;
    for (my $idx=0; $idx<@newFileLines; ++$idx) {
    	$line = $newFileLines[$idx];
        if ($line =~ m/^#include /) {
            $firstInclude = $idx;
            last;
        }
    }
    my $endInclude = -1;
    for (my $idx=@newFileLines; $idx>=0; --$idx) {
    	$line = $newFileLines[$idx];
        if ($line =~ m/^#include /) {
            $endInclude = $idx;
            last;
        }
    }
    
    my @aimLines = ();
    if ($firstInclude > 0 && $endInclude > 0) {
        for (my $idx=0; $idx<@newFileLines; ++$idx) {
        	$line = $newFileLines[$idx];            
            if ($idx < $firstInclude || $idx > $endInclude) {
                push @aimLines, $line;
            }
            else {
                if ($line !~ m/^\s*$/) {
                    push @aimLines, $line;
                }
                else { $needModify = 1; }
            }
        }
    }

    if (1 eq $needModify) {
		print __LINE__." need remove include: $path\n";
		FileOperate::writeFile($path, \@aimLines);
    }
}

1;

