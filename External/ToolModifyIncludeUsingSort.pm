#!/usr/bin/perl;

package ToolModifyIncludeUsingSort;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use Util;
use BuildMarco;
use FileOperate;
use Array::Compare;

sub modifySortIncludeUsingWithPaths {
    my $paths = shift;
    my @empty = ();
	&modifySortIncludeUsingWithPathsAndExcepts($paths, \@empty);
}

sub modifySortIncludeUsingWithPathsAndExcepts {
    my $paths = shift;
    my $exceptPaths = shift;
	my $allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".h");
	&doModifySortIncludeUsing($allFilesPath);

	$allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".cpp");
	&doModifySortIncludeUsing($allFilesPath);
}

sub doModifySortIncludeUsing {
    my $paths = shift;
    my $index = 0;
    my $comp = Array::Compare->new;
    foreach my $path (@$paths) {
        my $readFileDatas = FileOperate::readFile($path);
        my @writeFileDatas = @$readFileDatas;
        my $needModify = 0;

        my @records = ();
        # Type:
        # ==0 is include, ==1 is using, ==2 is empty line, ==3 is other
        my $line;
        my $endIdx = 0;
        for (my $idx=0; $idx<@writeFileDatas; ++$idx) {
        	$line = $writeFileDatas[$idx];

            if ($line =~ m/^#include\s+/ || $line =~ m/^\/\/\s*#include\s+/) {
				$endIdx = &getCurrTypeLastIdx(\@writeFileDatas, $idx, 0);

				my %lineInfo = ();
				$lineInfo{ "Type" } = 0;
				$lineInfo{ "StartIdx" } = $idx;
				$lineInfo{ "EndIdx" } = $endIdx;

				#print __LINE__." 0: $idx -> $endIdx\n";

	            push (@records, \%lineInfo);
	            $idx = $endIdx;
            }
            elsif ($line =~ m/^using\s+/ || $line =~ m/^\/\/\s*using\s+/) {
				$endIdx = &getCurrTypeLastIdx(\@writeFileDatas, $idx, 1);

				my %lineInfo = ();
				$lineInfo{ "Type" } = 1;
				$lineInfo{ "StartIdx" } = $idx;
				$lineInfo{ "EndIdx" } = $endIdx;

				#print __LINE__." 1: $idx -> $endIdx\n";

	            push (@records, \%lineInfo);
	            $idx = $endIdx;
            }
        }

        for (my $idx=@records-1; $idx>=0; --$idx) {
        	&sortSequence(\@writeFileDatas, $records[$idx]);
        }

		if (!$comp->compare(\@writeFileDatas, $readFileDatas)) {
    		print "--[sort:".__LINE__."] modify file: $path\n";
            FileOperate::writeFile($path, \@writeFileDatas);
  		}
    }
}

sub sortSequence {
	my $inputs = shift;
	my $recordInfo = shift;
	my @inputsTmps = @$inputs;

	my @sortLines = ();
	my %innerData = ();
	my $startIdx = $recordInfo->{ "StartIdx" };
	my $endIdx = $recordInfo->{ "EndIdx" };
	my $type = $recordInfo->{ "Type" };
	my $line;
	my $sortLine;

	my %innerData = ();
	for (my $idx=$startIdx; $idx<=$endIdx; ++$idx) {
		$line = $inputs->[$idx];
		if ($line !~ m/^\s*$/)	{
			if (0 eq $type) {
				$sortLine = $line;
				$sortLine =~ s/^\s*\/\/\s*//;
				$sortLine =~ s/\"//g;
				$sortLine =~ s/<//g;
				$sortLine =~ s/>//g;
				$sortLine =~ s/\//#/g;
				$sortLine =~ s/^.*?#include/#include/;
				$sortLine =~ s/\.h//;
				$sortLine =~ tr/[A-Z]/[a-z]/;

				$innerData{ $sortLine } = $line;
				push @sortLines, $sortLine;
			}
			elsif (1 eq $type) {
				$sortLine = $line;
				$sortLine =~ s/^\s*\/\/\s*//;
				$sortLine =~ s/\"//g;
				$sortLine =~ s/\///g;
				$sortLine =~ s/^.*?using/using/;
				$sortLine =~ tr/[A-Z]/[a-z]/;

				$innerData{ $sortLine } = $line;
				push @sortLines, $sortLine;
			}
			else {
			}
		}
	}

	my @elastosDroid = ();
	my @elastosCore = ();
	if (0 eq $type) {
		foreach my $item (@sortLines) {
			if ($item =~ m/droid/) {
				push @elastosDroid, $item;
			}
			else {
				push @elastosCore, $item;
			}
		}
	}
	elsif (1 eq $type) {
		foreach my $item (@sortLines) {
			if ($item =~ m/elastos::droid/) {
				push @elastosDroid, $item;
			}
			else {
				push @elastosCore, $item;
			}
		}
	}

	my $elastosDroidSize = @elastosDroid;
	my $elastosCoreSize = @elastosCore;
	@elastosDroid = sort @elastosDroid;
	@elastosCore = sort @elastosCore;

	# special sort for zhangleliang callback, this only occur in droid
	&specialSort(\@elastosDroid);

	my @sortedLines = ();
	foreach my $item (@elastosDroid) {
		push @sortedLines, $innerData{ $item };
	}
	foreach my $item (@elastosCore) {
		push @sortedLines, $innerData{ $item };
	}

	splice (@inputsTmps, $startIdx, $endIdx - $startIdx + 1, @sortedLines);
	@$inputs = @inputsTmps;
}

# special sort
# XXX_dec.h will after XXX.h, from callback by zhangleliang
sub specialSort {
	my $inputs = shift;
	my $item;
	my $srcFile;
	my @decInfos = ();
	my $srcIdx = 0;
	for (my $idx=0; $idx<@$inputs; ++$idx) {
		$item = $inputs->[$idx];
		if ($item =~ m/#(\d+|\w+)_dec\s*$/) {
			$srcFile = $1;
			$srcIdx = &findFileNameIdx($inputs, $srcFile);
			if ($srcIdx >= 0) {
				my %info = ();
				$info{ "SrcFile" } = $srcFile;
				$info{ "DecIdx" } = $idx;
				$info{ "SrcIdx" } = $srcIdx;
				push @decInfos, \%info;
				#print __LINE__." \$srcFile=$srcFile, decIdx=$idx, \$srcIdx=$srcIdx\n";
			}
		}
	}

	my $srcIdx = -1;
	my $decIdx = -1;
	foreach my $item (@decInfos) {
		$srcIdx = $item->{ "SrcIdx" };
		$decIdx = $item->{ "DecIdx" };
		if ($decIdx < $srcIdx && $decIdx >= 0) {
			Util::arraySwap($inputs, $srcIdx, $decIdx);
		}
	}
}

sub findFileNameIdx {
	my $inputs = shift;
	my $fileName = shift;
	my $item;
	for (my $idx=0; $idx<@$inputs; ++$idx) {
		$item = $inputs->[$idx];
		if ($item =~ m/#$fileName\s$/) {
			return $idx;
		}
	}
	return -1;
}

sub nextUsefulType {
	my $inputs = shift;
	my $startIdx = shift;
	my $line;
	for (my $idx=$startIdx; $idx<@$inputs; ++$idx) {
    	$line = $inputs->[$idx];

        if ($line =~ m/^#include\s+/ || $line =~ m/^\/\/\s*#include\s+/) {
			return 0;
        }
        elsif ($line =~ m/^using\s+/ || $line =~ m/^\/\/\s*using\s+/) {
			return 1;
        }
        elsif ($line =~ m/^\s*$/) {

        }
        else {
        	return 3;
        }
    }

    return -1;
}

sub getCurrTypeLastIdx {
	my $inputs = shift;
	my $currIdx = shift;
	my $currType = shift;
	my $typeTmp = -1;
	my $line;

	for (my $idx=$currIdx+1; $idx<@$inputs; ++$idx) {
    	$line = $inputs->[$idx];

        if ($line =~ m/^#include\s+/ || $line =~ m/^\/\/\s*#include\s+/) {
			$typeTmp = 0;
        }
        elsif ($line =~ m/^using\s+/ || $line =~ m/^\/\/\s*using\s+/) {
			$typeTmp = 1;
        }
        elsif ($line =~ m/^\s*$/) {
			$typeTmp = &nextUsefulType($inputs, $idx+1);
        }
        else {
        	$typeTmp = 3;
        }

        if ($currType ne $typeTmp) {
			return $idx-1;
        }
    }
    return $currType;
}


1;

