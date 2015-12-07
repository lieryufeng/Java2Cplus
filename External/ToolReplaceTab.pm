#!/usr/bin/perl;

package ToolReplaceTab;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( replaceTabInFiles, replaceTabInFilesAndExcepts );
use strict;
use BuildMarco;
use FileOperate;


sub replaceTabInFiles {
    my $paths = shift;
    my @empty;
	&replaceTabInFilesAndExcepts($paths, \@empty);
}

sub replaceTabInFilesAndExcepts {
    my $paths = shift;
    my $exceptPaths = shift;
	my $allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".h");
	&doReplaceTab($allFilesPath);
	$allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".cpp");
	&doReplaceTab($allFilesPath);
}

sub doReplaceTab {
    my $paths = shift;
    foreach my $path (@$paths) {
        my $readFileDatas = FileOperate::readFile($path);
        my @writeFileDatas;
        my $needModify = 0;
        foreach my $line (@$readFileDatas) {
            if ($line =~ m/\t/) {
                $line =~ s/\t/    /g;
                $needModify = 1;
            }
            push (@writeFileDatas, $line);
        }
        if (1 eq $needModify) {
            print "--[ToolReplaceTab.pm:".__LINE__."] replace tab: $path\n";
            FileOperate::writeFile($path, \@writeFileDatas);
        }
    }
}

1;

