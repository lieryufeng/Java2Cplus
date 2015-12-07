#!/usr/bin/perl;

package ToolDealImports;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use FileOperate;
use FileTag;
use FileAnalysisStruct;
use ElastosConfig;
use ElastosFilePathTry;
use TransElastosType;

my @gImportInfos = ();

sub analysisFilesImports
{
	my $currJavaPaths = shift;
	my @results = ();
    foreach my $path (@$currJavaPaths) {
    	my %info = ();
    	my @imports = ();
    	my @packages = ();
        &analysisFileImports($path, \@packages, \@imports);
        $info{ "PATH" } = $path;
        $info{ "IMPORTS" } = \@imports;
        $info{ "PACKAGES" } = \@packages;
        push @results, \%info;
    }
    return \@results;
}

sub analysisFileImportInfos
{
	my $currJavaPath = shift;
	my @packages = ();
	my @imports = ();
   	my $javaDataLines = &analysisFileImports($currJavaPath, \@packages, \@imports);
   	&resetImportInfo;
   	my $usingTmp;
   	foreach my $import (@imports) {
		&obtUsingByImportStr($import, \$usingTmp);
   	}

#=pod
	my $using;
	my $srcType;
	my $dstType;
	print __LINE__." curr java import infos: $currJavaPath\n";
	foreach my $importInfo (@gImportInfos) {
		$using = $importInfo->{ "USING_NAMESPACE" };
		$srcType = $importInfo->{ "SRC_TYPE" };
		$dstType = $importInfo->{ "DST_TYPE" };
		print __LINE__." \$using=$using, \$srcType=$srcType, \$dstType=$dstType\n";
	}
	print __LINE__." curr java import infos end\n";
#=cut

}

sub analysisFileImports
{
	my $currJavaPath = shift;
	my $packages = shift;
	my $imports = shift;

   	my $javaDataLines = FileOperate::readFile($currJavaPath);
   	&analysisImportsContext($javaDataLines, $packages, $imports);
}

sub analysisNodeImports
{
	my $node = shift;
	my $packages = shift;
	my $imports = shift;

	if (exists ($node->{ $FileTag::K_NodeType })) {
		my $type = $node->{ $FileTag::K_NodeType };
		if ("PACKAGE" eq $type) {
			push @$packages, $node->{ $FileTag::K_SelfData };
		}
		elsif ("IMPORT" eq $type) {
			push @$imports, $node->{ $FileTag::K_SelfData };
		}
	}
   	if (exists ($node->{ $FileTag::K_SubNodes })) {
		my $children = $node->{ $FileTag::K_SubNodes };
		foreach my $item (@$children) {
			&analysisNodeImports($item, $packages, $imports);
		}
	}
}

sub analysisImportsContext
{
   	my $javaDataLines = shift;
   	my $packages = shift;
	my $imports = shift;

	foreach my $line (@$javaDataLines) {
		if ($line =~ m/^package\s+/) {
			push @$packages, $line;
		}
		elsif ($line =~ m/^import\s+/) {
			push @$imports, $line;
		}
	}
}

sub obtUsingByImportStr
{
	my $import = shift;
	my $usingNamespacePtr = shift;

	my $importBuf = $import;
	$importBuf =~ s/^import\s+//;
	$importBuf =~ s/\s*;\s*//;
	$importBuf =~ s/\./_/g;
	#print __LINE__." \$import=$import, \$importBuf=$importBuf\n";
	my $lastSub = Util::getSplitSubStr($importBuf, "_", -1);
	$lastSub = ucfirst($lastSub);
	my $srcType = $lastSub;
	my $dstType = "I".$lastSub;

	$$usingNamespacePtr = &buildUsingnspaceByImportStr($import);
	my %importInfo = ();
	$importInfo{ "USING_NAMESPACE" } = $$usingNamespacePtr;
	$importInfo{ "SRC_TYPE" } = $srcType;
	$importInfo{ "DST_TYPE" } = $dstType;
	$import =~ s/^import\s+//;
	if ($import =~ m/^org/) { $importInfo{ "IS_CAR" } = 0; }
	else { $importInfo{ "IS_CAR" } = 1; }
	push @gImportInfos, \%importInfo;

	my $using = $$usingNamespacePtr;
	#print __LINE__." obtUsingByImportStr: \$using=$using\n";
}

sub obtUsingBySrcType
{
	my $srcType = shift;
	my $usingNamespacePtr = shift;
	$$usingNamespacePtr = "";
	my $src;
	foreach my $importInfo (@gImportInfos) {
		$src = $importInfo->{ "SRC_TYPE" };
		if ($src eq $srcType) {
			$$usingNamespacePtr = $importInfo->{ "USING_NAMESPACE" };
		}
	}

	my $using = $$usingNamespacePtr;
	#print __LINE__." obtUsingBySrcType: \$using=$using\n";
}

sub resetImportInfo
{
	@gImportInfos = ();
}

sub outputImportInfo
{
	my $include = "";
	my $absPath = "";
	my $usingNamespace = "";
	my $srcType = "";
	my $dstType = "";
	foreach my $item (@gImportInfos) {
		$usingNamespace = $item->{ "USING_NAMESPACE" };
		$srcType = $item->{ "SRC_TYPE" };
		$dstType = $item->{ "DST_TYPE" };
		print __LINE__." use: $usingNamespace\n";
		print __LINE__." src: $srcType\n";
		print __LINE__." dst: $dstType\n";
		print __LINE__." \n";
	}
}

sub isImportType
{
	my $type = shift;
	my $dstTypePtr = shift;
	$$dstTypePtr = "";
	#print __LINE__." \$type=$type\n";

	my $srcType;
	my $importInfosCnt = @gImportInfos;
	#print __LINE__." \$importInfosCnt=$importInfosCnt\n";
	foreach my $item (@gImportInfos) {
		$srcType = $item->{ "SRC_TYPE" };
		#print __LINE__." \$srcType=$srcType\n";
		if ($srcType eq $type) {
			$$dstTypePtr = $item->{ "DST_TYPE" };
			return 1;
		}
	}
	return 0;
}

sub isOneOfSpecipyImports
{
	my $imports = shift;
	my $type = shift;
	my $belongImportPtr = shift;
	$$belongImportPtr = "";
	my $typeFirstWord = "";
	if ($type =~ m/^(\w+|\d+)/) { $typeFirstWord = $1; }
	my $import = "";
	my $lastSub = "";
	foreach my $item (@$imports) {
		$import = $item;
		$import =~ s/^import\s+//;
		$import =~ s/\s*;\s*$//;
		$lastSub = Util::getSplitSubStr($import, qr/\./, -1);
		if ($lastSub eq $typeFirstWord) {
			$$belongImportPtr = $item;
			return 1;
		}
	}
	return 0;
}

sub isImportTypeIsCar
{
	my $type = shift;
	my $dstCarTypePtr = shift;
	if (defined($$dstCarTypePtr)) { $$dstCarTypePtr = ""; }
	my $result = 0;
	foreach my $item (@gImportInfos) {
		if ($item->{ "SRC_TYPE" } eq $type) {
			$result = $item->{ "IS_CAR" };
			if (1 eq $result && defined($$dstCarTypePtr)) { $$dstCarTypePtr = $item->{ "DST_TYPE" }; }
			return $result;
		}
	}
	return 0;
}

sub buildUsingnspacesByImport
{
	my $root = shift;
	my $usingNamespaces = shift;

	my ($findOk, $allChildrenSpecifyType) = $root->allChildrenSpecifyType("IMPORT");
	if (1 eq $findOk) {
		foreach my $item (@$allChildrenSpecifyType) {
			my $node = $item->{ "NODE" };
			my $index = $item->{ "INDEX" };
			my $selfData = $node->{ $FileTag::K_SelfData };
			$selfData =~ s/^import\s+//;

			my $absolutePath = "";
			&buildIncludesByImportStr($selfData, \$absolutePath);
			my $using = &buildUsingnspaceByImportStr($selfData);
			if ("" ne $using) {
				push @$usingNamespaces, $using;
			}
		}
	}
}

# input: import string and the file path that corresponding import string
sub buildUsingnspaceByImportStr
{
	my $import = shift;
	my $importTmp = $import;
	$importTmp =~ s/^\s*import\s+//;
	$importTmp =~ s/\s*;$//;
	$importTmp =~ s/\.util\./\.Utility\./;

	if ($importTmp =~ m/^android\./) {
		$importTmp =~ s/^android\.//;
		$importTmp =~ s/\./::/g;
		$importTmp = "Elastos::Droid::".$importTmp;
		if ($importTmp =~ m/::(\w+|\d+)\s*$/) {
			my $lastSub = "I".ucfirst($1);
			$importTmp =~ s/::(\w+|\d+)$/::/;
			$importTmp =~ s/\s*$//;
			$importTmp = $importTmp.$lastSub;
		}
	}
	elsif ($importTmp =~ m/^java\./) {
		$importTmp =~ s/^java\.//;
		$importTmp =~ s/\./::/g;
		$importTmp = "Elastos::".$importTmp;
		if ($importTmp =~ m/::(\w+|\d+)\s*$/) {
			my $lastSub = "I".ucfirst($1);
			$importTmp =~ s/::(\w+|\d+)$/::/;
			$importTmp =~ s/\s*$//;
			$importTmp = $importTmp.$lastSub;
		}
	}
	elsif ($importTmp =~ m/^javax\./) {
		$importTmp =~ s/^javax\.//;
		$importTmp =~ s/\./::/g;
		$importTmp = "Elastos::".$importTmp;
		if ($importTmp =~ m/::(\w+|\d+)\s*$/) {
			my $lastSub = "I".ucfirst($1);
			$importTmp =~ s/::(\w+|\d+)$/::/;
			$importTmp =~ s/\s*$//;
			$importTmp = $importTmp.$lastSub;
		}
	}

	$importTmp =~ s/\s*$//;
	my @subs = split(/::/, $importTmp);
	my $importSubs = Util::ucfirstArray(\@subs);
	$importTmp = join "::", @$importSubs;
	my $using = "using "."$importTmp;\n";
	return $using;
}


1;
