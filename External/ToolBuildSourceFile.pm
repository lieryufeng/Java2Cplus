#!/usr/bin/perl;

package ToolBuildSourceFile;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(  );
use strict;
use FileOperate;
use Util;

sub buildSourceNoRecursive
{
	my $srcDir = shift;
	my $dirInfos = FileOperate::readDirForMakefile($srcDir);
	my @keys = keys %$dirInfos;
	my $eachPath = "";
	foreach my $item (@keys) {
		$eachPath = $item;
		$eachPath =~ s/\/+$//;
		$eachPath = $eachPath."/sources";
		my $fileContexts = &buildSourceContext($item, $dirInfos->{ $item });
		if (@$fileContexts > 0) {
			FileOperate::writeFile($eachPath, $fileContexts);
			print __LINE__." source: $eachPath\n";
		}
	}
}

sub buildSourceAndSubsRecursive
{
	my $srcDir = shift;
	my $subDirs = FileOperate::readDirSubFoldersHasRecursive($srcDir);
	foreach my $path (@$subDirs) {
		&buildSourceNoRecursive($path);
	}
}

sub buildSourceContext
{
	my $dirPath = shift;
	my $filePaths = shift;
	my @results = ();

	# tar name
	# tar type
	# includes
	# sources
	&buildTargetContext($dirPath, \@results);
	&buildIncludesContext($dirPath, \@results);
	&buildCDefineContext($dirPath, \@results);
	&buildSourceLstContext($dirPath, $filePaths, \@results);

	return \@results;
}

sub buildTargetContext
{
	my $dirPath = shift;
	my $contexts = shift;

	my $tarName = Util::getFileNameNoEndPrefixByPath($dirPath);
	$tarName =~ s/_/\./g;
	$tarName =~ tr/[A-Z]/[a-z]/;
	push @$contexts, "TARGET_NAME = $tarName\n";
	push @$contexts, "TARGET_TYPE = lib\n";
	push @$contexts, "\n";
}

sub buildIncludesContext
{
	my $dirPath = shift;
	my $contexts = shift;

	my $upwardCnt = 0;
	my $upwardStr = "";
	{
		my $droidIdx = index($dirPath, "Droid/");
		$upwardStr = substr($dirPath, $droidIdx);
		$upwardStr =~ s/\/$//;
		my @tmpSubs = split(/\//, $upwardStr);
		$upwardCnt = @tmpSubs - 1;

		my $upwardMidStr = "";
		my $tmpCntBuf = $upwardCnt;
		while ($tmpCntBuf-- > 0) { $upwardMidStr = $upwardMidStr."../"; }
		push @$contexts, "include \$(MAKEDIR)/$upwardMidStr"."sources.inc\n";
		push @$contexts, "\n";
	}

	my $upwardStr1 = substr($upwardStr, index($upwardStr, "elastos/droid/") + length("elastos/droid/"));
	{
		my @tmpSubs = split(/\//, $upwardStr1);
		$upwardCnt = @tmpSubs - 1;

		my $lostPath = $upwardStr1;
		$lostPath =~ s/^Core\///;
		$lostPath =~ s/^src\//inc\//;
		print __LINE__." \$lostPath=$lostPath\n";

		my $upwardMidStr = "";
		my $tmpCntBuf = $upwardCnt;
		while ($tmpCntBuf-- > 0) { $upwardMidStr = $upwardMidStr."../"; }

		my @upwardEndStrs = ();
		my $lostPathTmp = $lostPath;
		while ($lostPathTmp =~ m/\/(\w+)$/) {
			my $item  = $1;
			last if ($item eq "native");
			push @upwardEndStrs, $lostPathTmp;
			$lostPathTmp =~ s/\/\w+$//;
		}
		@upwardEndStrs = reverse(@upwardEndStrs);

		my $upwardMidTmpStr = $upwardMidStr;
		$upwardMidTmpStr = Util::stringBeginTrimStr($upwardMidTmpStr, "../");
		push @$contexts, "INCLUDES += $upwardMidTmpStr\n";
		push @$contexts, "INCLUDES += \$(MAKEDIR)/$upwardMidStr"."inc/\n";
		my $idx = 0;
		while ($idx < @upwardEndStrs) {
			my $tmp = $upwardEndStrs[$idx++];
			push @$contexts, "INCLUDES += \$(MAKEDIR)/$upwardMidStr"."$tmp/\n";
		}
		push @$contexts, "\n";
	}
}

sub buildCDefineContext
{
	my $dirPath = shift;
	my $contexts = shift;
	push @$contexts, "C_DEFINES += -DDROID_CORE\n";
	push @$contexts, "\n";
}

sub buildSourceLstContext
{
	my $dirPath = shift;
	my $filePaths = shift;
	my $contexts = shift;

	my $first = 1;
	foreach my $item (@$filePaths) {
		if ($item =~ m/\/(\w+\.\w+)$/) {
			my $cppName = $1;
			if (1 eq $first) {
				$first = 0;
				push @$contexts, "SOURCES = $cppName\n";
			}
			else {
				push @$contexts, "SOURCES += $cppName\n";
			}
		}
	}
}


1;
