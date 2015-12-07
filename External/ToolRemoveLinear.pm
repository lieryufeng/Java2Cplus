#!/usr/bin/perl;

package ToolRemoveLinear;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( removeLinearInFiles, removeLinearInFilesAndExcepts );
use strict;
use BuildMarco;
use FileOperate;


sub removeLinearInFiles {
    my $paths = shift;
    my @empty = ();
	&removeLinearInFilesAndExcepts($paths, \@empty);
}

sub removeLinearInFilesAndExcepts {
    my $paths = shift;
    my $exceptPaths = shift;
	my $allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".h");
	&doRemoveLinear($allFilesPath);
	$allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".cpp");
	&doRemoveLinear($allFilesPath);
}

sub doRemoveLinear {
    my $paths = shift;
    foreach my $path (@$paths) {
        my $readFileDatas = FileOperate::readFile($path);
        my @writeFileDatas;
        my $needModify = 0;
        foreach my $line (@$readFileDatas) {
            if ($line =~ m/\r/) {
                $line =~ s/\r//g;
                $needModify = 1;
            }
            push (@writeFileDatas, $line);
        }
        if (1 eq $needModify) {
            print "--[ToolRemoveLinear.pm:".__LINE__."] remove linear: $path\n";
            FileOperate::writeFile($path, \@writeFileDatas);
        }
    }
}

1;
