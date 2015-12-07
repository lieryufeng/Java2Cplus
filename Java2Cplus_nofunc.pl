#!/usr/bin/perl;
use strict;
use Cwd;
my $gCurrDir = getcwd;

# package name must be equal to file name.
=pod windows
BEGIN {
	push @INC, "E:/self/program/perl/JavaToCplus_by_pm";
	push @INC, "E:/self/program/perl/JavaToCplus_by_pm/External";
}
=cut

#=pod ubuntu
BEGIN {
    unshift @INC, $ENV{"PWD"};
    unshift @INC, $ENV{"PWD"}."/External";
}
#=cut

use FileOperate;
use FileAnalysisJavaNoFunc;
use FileAnalysisJavaOnlyClass;
use FileAnalysisJavaPolishC;
use FileAnalysisJavaOutputC;
use FileAnalysisC_doth;
use ToolDealImports;
use BuildIncludes;
use BuildNamespace;
use AndroidFilePathTry;
use FileAnalysisJavaPolishC_while;

my $gIsTesting = 0;
my $ret = &main;

sub main
{
	$gIsTesting = 1;
	# unlink all specify files
	if (0 eq $gIsTesting) {
		my $srcDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core";
		my @exceptsPath = ();
		FileOperate::unlinkFilesInDir($srcDir, ".h");
		FileOperate::unlinkFilesInDir($srcDir, ".cpp");
	}
	# just analysis single file
	elsif (1 eq $gIsTesting) {
		my $path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/widget/DayPickerView.java";
		&javaToCplus($path, 0);
		$path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/widget/TimePicker.java";
		&javaToCplus($path, 0);
		$path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/widget/TimePickerClockDelegate.java";
		&javaToCplus($path, 0);
		$path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/widget/TimePickerSpinnerDelegate.java";
		&javaToCplus($path, 0);
	}
	# analysis files and move to target path
	elsif (2 eq $gIsTesting) {
		my $srcDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/webkit/chromium/ContentSettingsAdapter.java";
		my @exceptsPath = ();
		#push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/webkit/native/content";

		my $dstHDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
		my $dstCDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/ui";
		my $files = FileOperate::readDirAndExcepts($srcDir, \@exceptsPath, ".java");
		if (@$files eq 0) { print __LINE__." has no file.\n"; <STDIN>; }
		my @mayNoNeedCpps = ();
		foreach (@$files) {
	    	my $tmp = &javaToCplus($_, 0);
	    	if ("" ne $tmp) { push @mayNoNeedCpps, $tmp; }
	    }
		if (@mayNoNeedCpps > 0) {
			print __LINE__." donot need cpp files:\n";
		    foreach (@mayNoNeedCpps) { print "$_\n"; }
		}
	}
	# test import translated
	elsif (3 eq $gIsTesting) {
		my $srcDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/webkit/native";
		my $files = FileOperate::readDir($srcDir, ".java");
		my $results = ToolDealImports::analysisFilesImports($files);
		foreach my $item (@$results) {
			my $path = $item->{ "PATH" };
			my $imports = $item->{ "IMPORTS" };
			print __LINE__." start:==========================================\n \$path=$path\n";
			foreach my $srcimport (@$imports) {
				print " import: $srcimport";
				my $absolutePath = "";
				my $dstInclude;# = BuildIncludes::buildIncludesByImportStr($srcimport, \$absolutePath);
				my $dstusing = BuildNamespace::buildUsingnspaceByImportStr($srcimport);
				print " ->incl: $dstInclude";
				#if ("" eq $dstInclude) { <STDIN>; }
				print " ->name: $dstusing";
				#if ("" eq $dstusing) { print "\n";; }
				print "\n";
			}
		}
	}
	# test import translate to java path
	elsif (4 eq $gIsTesting) {
		AndroidFilePathTry::obtAllJavaFilePaths;
		my $testSpecial = 1;
		if (0 eq $testSpecial) {
			my $srcDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/webkit/native";
			my $files = FileOperate::readDir($srcDir, ".java");
			my $results = ToolDealImports::analysisFilesImports($files);
			foreach my $item (@$results) {
				my $path = $item->{ "PATH" };
				my $imports = $item->{ "IMPORTS" };
				print __LINE__." start:==========================================\n \$path=$path\n";
				foreach my $srcimport (@$imports) {
					print " import: $srcimport";
					my ($find, $aimPath) = AndroidFilePathTry::obtImportStr2JavaPath($srcimport);
					if (1 eq $find) {
						print __LINE__." find = 1: $aimPath\n";
					}
					else {
						print __LINE__." find = 0\n";
					}
					print "\n";
				}
			}
		}
		else {
			#my $srcimport = "import android.app.Dialog;";
			my $srcimport = "import android.content.DialogInterface;";
			my ($find, $aimPath) = AndroidFilePathTry::obtImportStr2JavaPath($srcimport);
			if (1 eq $find) {
				print __LINE__." find = 1: $aimPath\n";
			}
			else {
				print __LINE__." find = 0\n";
			}
			print "\n";
		}
	}
	# test analysisC++ .h
	elsif (5 eq $gIsTesting) {
		my $path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/webkit/native/ui/ColorSuggestionListAdapter.h";
		my $doc = FileAnalysisC_doth::analysisC_doth($path);
		$doc->testOutputStruct("");
	}
	elsif (6 eq $gIsTesting) {
		my $path = "/home/lieryufeng/self/program/__work__/Android5_0_2_Actions/android/frameworks/base/core/java/android/view/View.java";
		my $doc = FileAnalysisJavaOnlyClass::analysisFile($path, 1, 1);
		FileAnalysisJavaOnlyClass::obtAllClassPathInJavaPath($path);
		$doc->testOutputStruct("");
	}
}

sub javaToCplus
{
	my $filePath = shift;
	my $analysisFuncContent = shift;
    my $doc = FileAnalysisJavaNoFunc::analysisFile($filePath, $analysisFuncContent, 1);
    #print __LINE__."-----------------------------javaToCplus all importinfos start----------------------------------\n";
    #ToolDealImports::outputImportInfo();
    #print __LINE__."-----------------------------javaToCplus all importinfos end----------------------------------\n\n";

    #print __LINE__."-----------------------------javaToCplus before polish src start----------------------------------\n";
    #$doc->testOutputStruct("");
    #print __LINE__."-----------------------------javaToCplus before polish src end----------------------------------\n\n";

    print __LINE__."-----------------------------polish start--------------------------------\n";
    my ($dotHContext, $dotCppContext) = FileAnalysisJavaPolishC::polishAnalisisStruct($doc);
    FileAnalysisJavaPolishC_while::polishAnalisisStruct($dotHContext, $dotCppContext);
    #print __LINE__."-----------------------------polish test output-doth-----------------------------\n";
    #$dotHContext->testOutputStruct("");
    #print __LINE__."-----------------------------polish test output-dotcpp-----------------------------\n";
    #$dotCppContext->testOutputStruct("");
    print __LINE__."-----------------------------polish end----------------------------------\n\n";
    FileAnalysisJavaOutputC::outputAnalisisStruct($dotHContext, $dotCppContext);

	my $cppPath = "";
    if (0 eq FileAnalysisJavaOutputC::outputCppControl($dotCppContext)) {
		$cppPath = $dotCppContext->{ $FileTag::K_NodeName };
		$cppPath =~ s/\.java/\.cpp/g;
    }
    return $cppPath;
}


