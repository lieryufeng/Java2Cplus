#!/usr/bin/perl;

package ToolModifyMacro;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( modifyMacroWithPaths, modifyMacroWithPathsAndExcepts );
use strict;
use BuildMarco;
use FileOperate;

sub modifyMacroWithPaths {
    my $paths = shift;
    my @empty = ();
	&modifyMacroWithPathsAndExcepts($paths, \@empty);
}

sub modifyMacroWithPathsAndExcepts {
    my $paths = shift;
    my $exceptPaths = shift;
	my $allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".h");
	&doModifyMacro($allFilesPath);
}

sub doModifyMacro {
    my $paths = shift;
    foreach my $path (@$paths) {
        my $macro = BuildMarco::buildMacro($path);
        my $readFileDatas = FileOperate::readFile($path);
        my @writeFileDatas;
        my $needModify = 0;
        foreach my $line (@$readFileDatas) {
            if ($line =~ m/^#ifndef\s+(\S+)/) {
                my $mach = $1;
                if ($mach ne $macro) {
                    $line = "#ifndef $macro\n";
                    $needModify = 1;
                }
            }
            elsif ($line =~ m/^#define\s+(\S+)/) {
                my $mach = $1;
                if ($mach ne $macro) {
                    $line = "#define $macro\n";
                    $needModify = 1;
                }
            }
            elsif ($line =~ m/^#endif\s+\/\/\s+(\S+)/) {
                my $mach = $1;
                if ($mach ne $macro) {
                    $line = "#endif \/\/\ $macro\n";
                    $needModify = 1;
                }
            }
            push (@writeFileDatas, $line);
        }
        if (1 eq $needModify) {
            print "--[ToolModifyMacro.pm:".__LINE__."] macro: $macro\n";
            print "--[ToolModifyMacro.pm:".__LINE__."] modify file: $path\n";
            FileOperate::writeFile($path, \@writeFileDatas);
        }
    }
}

1;
