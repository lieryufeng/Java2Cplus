#!/usr/bin/perl;

package ElastosFilePathTry;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use Util;
use FileOperate;
use ElastosConfig;


# input:
=pod
import android.app.PendingIntent;
import android.content.res.Configuration;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.view.View;
import android.view.ViewGroup.MarginLayoutParams;
import android.view.ViewTreeObserver;
import android.widget.ImageView;
import android.widget.RemoteViews;
import android.widget.TextView;
=cut
# return: using ***;\n
sub getUsingByImportAndroid
{
	my $import = shift;
	my $importTmp = Util::stringTrim($import);
	$importTmp =~ s/^import\s+//;
	if ($importTmp !~ m/^android\./) {
		print __LINE__." getIncludeByImportAndroid input start with android\n";
		<STDIN>;
		return "";
	}
	$importTmp =~ s/^android\.//;
	$importTmp =~ s/\s*;$//;
	my @tmps = split(/\./, $importTmp);
	if (@tmps eq 2) {
		my $arrayTmps = Util::ucfirstArray(\@tmps);
		@tmps = @$arrayTmps;

		my $last = $tmps[$#tmps];
		$last = ucfirst($last);
		$last = "I".$last;
		$tmps[$#tmps] = $last;
		my $tmp = join "::", @tmps;
		my $result = "using Elastos::Droid::".$tmp.";\n";
		return $result;
	}
	elsif (@tmps > 2) {
		my $currPath = $ElastosConfig::CFG_ELASTOS_INC_BASE;
		my $currPathTmp = $currPath;
		my $hasCorrespondingFolderIdx = -1;

		for (my $idx=0; $idx<@tmps; ++$idx) {
			my $item = $tmps[$idx];
			$currPathTmp = $currPathTmp."/$item";
			if (-d $currPathTmp) {
				++$hasCorrespondingFolderIdx;
				$currPath = $currPath."/$item";
			}
			else {
				if ($hasCorrespondingFolderIdx < 0) {
					print __LINE__."donot match any sub folders, failed!\n";
					<STDIN>;
					return "";
				}

				my $arrayTmps = Util::ucfirstArray(\@tmps);
				@tmps = @$arrayTmps;

				my $usedTmps = Util::arraySplice(\@tmps, 0, $hasCorrespondingFolderIdx+1);
				my $usedTmp = join "::", @$usedTmps;

				my $lastTmp = Util::arraySplice(\@tmps, $hasCorrespondingFolderIdx+1);
				my $tmp = join "", @$lastTmp;
				my $tmp0 = $currPath."/".$tmp.".h";
				my $tmp1 = $currPath."/"."I".$tmp .".h";
				my $tmp2 = $currPath."/"."C".$tmp .".h";

				if (-e $tmp0 || -e $tmp1 || -e $tmp2) {
					my $result = "using Elastos::Droid::".$usedTmp."::I$tmp;\n";
					return $result;
				}
				else {
					return "";
				}
			}
		}
		return "";
	}
	else {
		print __LINE__." else, is it input ok? $import=$import\n";
		<STDIN>;
		return "";
	}
}

sub getUsingByImportOrg
{
	my $import = shift;
	my $importTmp = Util::stringTrim($import);
	$importTmp =~ s/^import\s+//;
	if ($importTmp !~ m/^org\./) {
		print __LINE__." getIncludeByImportAndroid input start with android\n";
		<STDIN>;
		return "";
	}
	$importTmp =~ s/^org\.//;
	$importTmp =~ s/^chromium\.//;
	$importTmp =~ s/\s*;$//;
	my @tmps = split(/\./, $importTmp);
	if (@tmps eq 2) {
		my $arrayTmps = Util::ucfirstArray(\@tmps);
		@tmps = @$arrayTmps;

		my $last = $tmps[$#tmps];
		$last = ucfirst($last);
		$tmps[$#tmps] = $last;
		my $tmp = join "::", @tmps;
		my $result = "";
		my $chkFileTmp = $importTmp;
		$chkFileTmp =~ s/\./\//g;
		my $dotHFile = $chkFileTmp.".h";
		if (1 eq &findAndMayModifyFileByOrg(\$dotHFile)) {
			$result = "using Elastos::Droid::Webkit::".$tmp.";\n";
		}
		else {
			#$result = "// using Elastos::Droid::Webkit::".$tmp.";\n";
		}
		return $result;
	}
	elsif (@tmps > 2) {
		my $currPath = $ElastosConfig::CFG_ELASTOS_INC_BASE."/webkit/native";
		my $currPathTmp = $currPath;
		my $hasCorrespondingFolderIdx = -1;

		for (my $idx=0; $idx<@tmps; ++$idx) {
			my $item = $tmps[$idx];
			$currPathTmp = $currPathTmp."/$item";
			print __LINE__."\$currPathTmp=$currPathTmp\n";
			if (-d $currPathTmp) {
				++$hasCorrespondingFolderIdx;
				$currPath = $currPath."/$item";
			}
			else {
				if ($hasCorrespondingFolderIdx < 0) {
					print __LINE__."donot match any sub folders, failed! \$currPath=$currPath, \$currPathTmp=$currPathTmp\n";
					#<STDIN>;
					return "";
				}

				my $arrayTmps = Util::ucfirstArray(\@tmps);
				@tmps = @$arrayTmps;

				my $usedTmps = Util::arraySplice(\@tmps, 0, $hasCorrespondingFolderIdx+1);
				my $usedTmp = join "::", @$usedTmps;

				my $lastTmp = Util::arraySplice(\@tmps, $hasCorrespondingFolderIdx+1);
				my $tmp = join "", @$lastTmp;
				my $tmp0 = $currPath."/".$tmp.".h";
				my $tmp1 = $currPath."/"."I".$tmp .".h";
				my $tmp2 = $currPath."/"."C".$tmp .".h";

				if (-e $tmp0 || -e $tmp1 || -e $tmp2) {
					my $result = "";
					my $chkFileTmp = $currPath;
					$chkFileTmp =~ s/\./\//g;
					my $dotHFile = $chkFileTmp.".h";
					if (1 eq &findAndMayModifyFileByOrg(\$dotHFile)) {
						$result = "using Elastos::Droid::Webkit::".$usedTmp."::$tmp;\n";
					}
					else {
						#$result = "// using Elastos::Droid::Webkit::".$usedTmp."::$tmp;\n";
					}
					return $result;
				}
				else {
					return "";
				}
			}
		}
		return "";
	}
	else {
		print __LINE__." else, is it input ok? $import=$import\n";
		<STDIN>;
		return "";
	}
}

sub getUsingByImportJava
{
	my $import = shift;
	my $importTmp = Util::stringTrim($import);
	$importTmp =~ s/^import\s+//;
	if ($importTmp !~ m/^java\./) {
		print __LINE__." getUsingByImportJava donot start with java.\n";
		<STDIN>;
		return "";
	}
	$importTmp =~ s/^java\.//;
	if ($importTmp =~ m/^lang\./) {
		return "";
	}

	$importTmp =~ s/\s*;$//;
	my @tmps = split(/\./, $importTmp);
=pod
	if (@tmps eq 2) {
		my $arrayTmps = Util::ucfirstArray(\@tmps);
		@tmps = @$arrayTmps;

		my $last = $tmps[$#tmps];
		$last = ucfirst($last);
		$last = "I".$last;
		$tmps[$#tmps] = $last;
		my $tmp = join "::", @tmps;
		my $result = "using Elastos::".$tmp.";\n";
		return $result;
	}
=cut
	if (@tmps >= 2) {
		my $currPath = ElastosConfig::getElastosLibcoreInc."/elastos";
		my $currPathTmp = $currPath;
		my $hasCorrespondingFolderIdx = -1;

		for (my $idx=0; $idx<@tmps; ++$idx) {
			my $item = $tmps[$idx];
			$currPathTmp = $currPathTmp."/$item";
			if (-d $currPathTmp) {
				++$hasCorrespondingFolderIdx;
				$currPath = $currPath."/$item";
			}
			else {
				if ($hasCorrespondingFolderIdx < 0) {
					print __LINE__."donot match any sub folders, failed! \$import=$import\n";
					#<STDIN>;
					return "";
				}

				my $arrayTmps = Util::ucfirstArray(\@tmps);
				@tmps = @$arrayTmps;

				my $usedTmps = Util::arraySplice(\@tmps, 0, $hasCorrespondingFolderIdx+1);
				my $usedTmp = join "::", @$usedTmps;

				my $lastTmp = Util::arraySplice(\@tmps, $hasCorrespondingFolderIdx+1);
				my $tmp = join "", @$lastTmp;
				my $tmp0 = $currPath."/".$tmp.".h";
				my $tmp1 = $currPath."/"."I".$tmp .".h";
				my $tmp2 = $currPath."/"."C".$tmp .".h";

				if (-e $tmp0 || -e $tmp1 || -e $tmp2) {
					my $result = "using Elastos::".$usedTmp."::I$tmp;\n";
					return $result;
				}
				else {
					return "";
				}
			}
		}
		return "";
	}
	else {
		print __LINE__." else, is it input ok? $import=$import\n";
		<STDIN>;
		return "";
	}
}

sub findAndMayModifyFileByOrg
{
	my $fileRelativePath = shift;
	my $absoluPathPtr = shift;

	my $elastosBase = $ElastosConfig::CFG_ELASTOS_INC_BASE;
	my $pathTmp = $elastosBase."/webkit/native";
	$pathTmp = $pathTmp."/".$$fileRelativePath;

	#print __LINE__." org: \$pathTmp=$pathTmp\n";
	if (1 eq FileOperate::isFileExists($pathTmp)) {
		$$absoluPathPtr = $pathTmp;
		return 1;
	}
	return 0;
}

sub findAndMayModifyFileByAndroid
{
	my $fileRelativePath = shift;
	my $absoluPathPtr = shift;

	my $elastosBase = $ElastosConfig::CFG_ELASTOS_INC_BASE;
	my $pathTmp = $elastosBase;
	$pathTmp = $pathTmp."/".$$fileRelativePath;
	#print __LINE__." \$fileRelativePath=$$fileRelativePath, \$pathTmp=$pathTmp\n";
	if (1 eq FileOperate::isFileExists($pathTmp)) {
		$$absoluPathPtr = $pathTmp;
		return 1;
	}

	my @tmps = split(/\//, $$fileRelativePath);
	my $last = $tmps[$#tmps];
	$last = ucfirst($last);
	$last = "C".$last;
	$tmps[$#tmps] = $last;
	my $newFileRelativePath = join "/", @tmps;
	my $elastosBase = $ElastosConfig::CFG_ELASTOS_INC_BASE;
	$pathTmp = $elastosBase;
	$pathTmp = $pathTmp."/".$newFileRelativePath;
	if (1 eq FileOperate::isFileExists($pathTmp)) {
		$$fileRelativePath = $newFileRelativePath;
		$$absoluPathPtr = $pathTmp;
		#print __LINE__." try: new : \$newFileRelativePath=$newFileRelativePath\n";
		return 1;
	}
	return 0;
}

sub findAndMayModifyFileByJava
{
	my $fileRelativePath = shift;
	my $absoluPathPtr = shift;

	my $elastosLibcoreInc = ElastosConfig::getElastosLibcoreInc;
	$elastosLibcoreInc =~ s/\/$//;
	$$fileRelativePath =~ s/^\///;

	my $pathTmp = $elastosLibcoreInc."/".$$fileRelativePath;
	if (1 eq FileOperate::isFileExists($pathTmp)) {
		$$absoluPathPtr = $pathTmp;
		return 1;
	}

	my @tmps = split(/\//, $$fileRelativePath);
	my $last = $tmps[$#tmps];
	$last = ucfirst($last);
	$last = "C".$last;
	$tmps[$#tmps] = $last;
	my $newFileRelativePath = join "/", @tmps;
	$pathTmp = $elastosLibcoreInc."/".$newFileRelativePath;
	if (1 eq FileOperate::isFileExists($pathTmp)) {
		$$fileRelativePath = $newFileRelativePath;
		$$absoluPathPtr = $pathTmp;
		print __LINE__." try: new : \$newFileRelativePath=$newFileRelativePath\n";
		return 1;
	}
	return 0;
}

sub findAndMayModifyFileByJavax
{
	my $fileRelativePath = shift;
	my $absoluPathPtr = shift;

	my $elastosLibcoreInc = ElastosConfig::getElastosLibcoreInc;
	$elastosLibcoreInc =~ s/\/$//;
	$$fileRelativePath =~ s/^\///;

	my $pathTmp = $elastosLibcoreInc."/".$$fileRelativePath;
	if (1 eq FileOperate::isFileExists($pathTmp)) {
		$$absoluPathPtr = $pathTmp;
		return 1;
	}

	my @tmps = split(/\//, $$fileRelativePath);
	my $last = $tmps[$#tmps];
	$last = ucfirst($last);
	$last = "C".$last;
	$tmps[$#tmps] = $last;
	my $newFileRelativePath = join "/", @tmps;
	$pathTmp = $elastosLibcoreInc."/".$newFileRelativePath;
	if (1 eq FileOperate::isFileExists($pathTmp)) {
		$$fileRelativePath = $newFileRelativePath;
		$$absoluPathPtr = $pathTmp;
		print __LINE__." try: new : \$newFileRelativePath=$newFileRelativePath\n";
		return 1;
	}
	return 0;
}



1;