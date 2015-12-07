#!/usr/bin/perl;

package ToolModifyNoteInAddBrackets;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( modifyNoteInAddBracketsWithPaths, modifyNoteInAddBracketsWithPathsAndExcepts );
use strict;
use BuildMarco;
use FileOperate;

sub modifyNoteInAddBracketsWithPaths {
    my $paths = shift;
    my @empty = ();
	&modifyNoteInAddBracketsWithPathsAndExcepts($paths, \@empty);
}

sub modifyNoteInAddBracketsWithPathsAndExcepts {
    my $paths = shift;
    my $exceptPaths = shift;
	my $allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".h");
	&doModifyNoteInAddBrackets($allFilesPath);
}

sub doModifyNoteInAddBrackets {
    my $paths = shift;
    foreach my $path (@$paths) {
        my $readFileDatas = FileOperate::readFile($path);
        my @writeFileDatas;
        my $needModify = 0;
        foreach my $line (@$readFileDatas) {
            if ($line =~ m/^\s+(\/\*\s+in\s+\*\/\s+)/) {
                $line =~ s/\/\*\s+in\s+\*\/\s+/\/\* [in] \*\/ /;
                $needModify = 1;
            }
            push (@writeFileDatas, $line);
        }
        if (1 eq $needModify) {
            print "--[ToolModifyNoteInAddBrackets.pm:".__LINE__."] modify /* in */: $path\n";
            FileOperate::writeFile($path, \@writeFileDatas);
        }
    }
}

1;
