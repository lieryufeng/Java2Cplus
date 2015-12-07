#!/usr/bin/perl;

package ToolBuildDirsFile;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(  );
use strict;
use FileOperate;
use Util;

sub buildDirsNoRecursive
{
	my $srcDir = shift;
	my $subDirs = FileOperate::readDirSubFoldersNoRecursive($srcDir);
	my $subFolderName = "";
	my @usefullSubs = ();
	my $first = 1;
	foreach my $path (@$subDirs) {
		$subFolderName = Util::getFileNameByPath($path);
		next if ($subFolderName =~ m/^test/);
		if (1 eq $first) {
			$first = 0;
			push @usefullSubs, "DIRS = ".$subFolderName."\n";
		}
		else {
			push @usefullSubs, "DIRS += ".$subFolderName."\n";
		}
	}

	if (@usefullSubs > 0) {
		$srcDir =~ s/\/$//;
		my $targetDirsPath = $srcDir."/dirs";
		FileOperate::writeFile($targetDirsPath, \@usefullSubs);
	}

	print __LINE__." bld_dir: $srcDir\n";
}

sub buildDirsAndSubsRecursive
{
	my $srcDir = shift;
	my $subDirs = FileOperate::readDirSubFoldersHasRecursive($srcDir);
	foreach my $path (@$subDirs) {
		&buildDirsNoRecursive($path);
	}
}


1;