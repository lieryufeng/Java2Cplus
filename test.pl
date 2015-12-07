#!/usr/bin/perl;

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

use Cwd;
use strict;
use warnings;
use BuildNamespace;
use BuildMarco;
use FileOperate;
use FileTag;
use BuildElastosPath;
use ElastosFilePathTry;
use FileAnalysisStruct;
use FileAnalysisC_doth;

use ToolModifyMacro;
use ToolModifyNamespace;
use ToolcheckObviousError;
use ToolModifyNoteInAddBrackets;
use ToolRemoveLinear;
use ToolReplaceTab;
use ToolBuildSourceFile;
use ToolModifyStringToConst;
use ToolRemoveNoUsedInclude;
use ToolModifyIncludeUsingSort;
use ToolFindLeftAutoPtrWhenProbe;
use ToolFindLogString;
use ToolFindProbeIInterface;
use ToolFindThisProbe;
use ToolFindOutParamHasRefAdd;
use TransElastosType;

my $ret = &main;

sub main
{
	# &modifyCpp;
	# &testToolModifyStringToConst;
	# &testToolRemoveNoUsedInclude;
	# &testTransElastosType;
	# &testFileAnalysisStruct;
	# &testToolModifyNamespaceBeginEnd;
    # &testBuildElastosPath;
    # &testElastosFilePathTry;
    # &testToolRemoveLinear;
    # &testToolReplaceTab;
    # &testToolModifyNoteInAddBrackets;
    # &testFileTag;
    # &testToolCheckObviousError;
    # &testToolModifyMacro;
    # &testToolBuildSourceFile;
    # &testQE;
    # &testBuildNamespace;
    # &testBuildMarco;
    # &testFileOperate;
    # &testReg;
    # &testFunc;
    # &testMachReg;
    # &testSortStr;
     &testModifyIncludeUsing;
    # &testSplice;
    # &testFindLeftAutoPtrWhenProbe;
    # &testFindLoggerString;
    # &testFindProbeIInterface;
    # &testFindThisProbe;
    # &testFindOutParamHasRefAdd;
    return 0;
}

sub modifyCpp
{
	my $srcPath = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/webview/chromium";

	my $filePaths = FileOperate::readDir($srcPath, ".h");
	foreach my $path (@$filePaths) {
		my $fileLines = FileOperate::readFile($path);

		my @aimLines = ();
		my $currClassName;
		my $parentClassName;
		my $line;
		my $beginSpace;
		my $trimline;

		my $currFileNeedRewrite = 0;
		for (my $idx = 0; $idx < @$fileLines; ++$idx) {
			$line = $fileLines->[$idx];

			if ($line =~ m/^\s*class (\w+)/ && $line =~ m/:/) {
				$currFileNeedRewrite = 1;
				$currClassName = $1;
				$parentClassName = $2;
				print __LINE__." \$path=$path\n";

				#$beginSpace = Util::getBeginSpaceOfStr($line);
				#push @aimLines, $beginSpace."class $currClassName\n";
				#push @aimLines, $beginSpace."    : public $parentClassName\n";
			}
			else {
				#push @aimLines, $line;
			}
		}

		if (1 eq $currFileNeedRewrite) {
			#my $dstPath = $path.".tmp";
			#print __LINE__." \$dstPath=$dstPath\n";
			#unlink $dstPath;
			#FileOperate::writeFile($path, \@aimLines);
		}
	}
}

sub testToolModifyStringToConst
{
	my $srcDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core";
    my $filesPaths = FileOperate::readDir($srcDir, ".h");
    ToolModifyStringToConst::modifyStringWithPaths($filesPaths);
    $filesPaths = FileOperate::readDir($srcDir, ".cpp");
    ToolModifyStringToConst::modifyStringWithPaths($filesPaths);
}

sub testToolRemoveNoUsedInclude
{
	my $srcDir = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core";
    my $filesPaths = FileOperate::readDir($srcDir, ".h");
    ToolRemoveNoUsedInclude::removeNoUsedIncludeWithPaths($filesPaths);
    $filesPaths = FileOperate::readDir($srcDir, ".cpp");
    ToolRemoveNoUsedInclude::removeNoUsedIncludeWithPaths($filesPaths);
}

sub testTransElastosType
{
	my $input = "ViewTreeObserver::OnPreDrawListener";
	my $toint = "const Map<String, AutoPtr<IList<ArrayOf<Byte>, String> > >";

	my $dotHret = TransElastosType::transComplexReturnElastosType($input, 0);
	my $dotCppret = TransElastosType::transComplexReturnElastosType($input, 1);
	my $var = TransElastosType::transComplexVarDefineElastosType($input);
	my $parm = TransElastosType::transComplexParamElastosType($input);
	print __LINE__." --\$input=$input\n";
	print __LINE__." --\$dotHret=$dotHret\n";
	print __LINE__." --\$dotCppret=$dotCppret\n";
	print __LINE__." --\$var=$var\n";
	print __LINE__." --\$parm=$parm\n";
	#print __LINE__." \$input=$input, \$var=$var\n";
}

sub testFileAnalysisStruct
{
	# &javaToCplus("/home/lieryufeng/self/program/Self_Project/JavaToCplus_by_pm/DownloadController.java");
	my $doc = createRootNode FileAnalysisStruct;
	$doc->{ $FileTag::K_NodeType } = "CLASS";
	$doc->{ $FileTag::K_NodeName } = "classA";
	$doc->{ $FileTag::K_SelfData } = "";

	{
		my $child = new FileAnalysisStruct;
		$child->{ $FileTag::K_NodeType } = "VAR";
		$child->{ $FileTag::K_NodeName } = "varA";
		$child->{ $FileTag::K_SelfData } = "";
		print __LINE__." appendChildNode, before\n";
		$doc->appendChildNode($child);
		print __LINE__." appendChildNode, after\n";
	}
	{
		my $child = new FileAnalysisStruct;
		$child->{ $FileTag::K_NodeType } = "VAR";
		$child->{ $FileTag::K_NodeName } = "varB";
		$child->{ $FileTag::K_SelfData } = "";
		print __LINE__." appendChildNode, before\n";
		$doc->appendChildNode($child);
		print __LINE__." appendChildNode, after\n";
	}
	{
		my $child = new FileAnalysisStruct;
		$child->{ $FileTag::K_NodeType } = "VAR";
		$child->{ $FileTag::K_NodeName } = "varC";
		$child->{ $FileTag::K_SelfData } = "";
		print __LINE__." appendChildNode, before\n";
		$doc->appendChildNode($child);
		print __LINE__." appendChildNode, after\n";
	}
	$doc->testOutputStruct("");
}

sub testToolModifyNamespaceBeginEnd
{
    my @filesPath;
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
	push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/net";

	#push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui/Interpolators";


    my @exceptsPath;
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Base";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Autofill";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Gfx";

    my @empty;
    ToolModifyNamespace::modifyNamespaceWithPathsAndExcepts(\@filesPath, \@empty);
}

sub testBuildElastosPath
{
    my $path;
    #$path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Interpolators";
	$path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/view/menu/ActionMenu.h";
    my $elastosPath = BuildElastosPath::buildElastosPath($path);
    print __LINE__." \$elastosPath=$elastosPath\n";
}

sub testElastosFilePathTry
{
	my @tmps = ();
=pod
	push @tmps, "import android.app.PendingIntent;";
	push @tmps, "import android.os.Build;";
	push @tmps, "import android.view.View;";
	push @tmps, "import android.view.ViewTreeObserver;";
	push @tmps, "import android.widget.ImageView;";
	push @tmps, "import android.widget.RemoteViews;";
	push @tmps, "import android.widget.TextView;";
=cut

	push @tmps, "import android.content.res.Configuration;";
	push @tmps, "import android.graphics.drawable.Drawable;";
	push @tmps, "import android.view.ViewGroup.MarginLayoutParams;";

	push @tmps, "import android.content.pm.ApplicationInfo;";
	push @tmps, "import android.content.pm.PackageInfo;";
	push @tmps, "import android.content.pm.PackageManager;";
	push @tmps, "import android.content.pm.PackageManager.NameNotFoundException;";

	foreach my $item (@tmps) {
		my $result = ElastosFilePathTry::getUsingByImportAndroid($item);
		print __LINE__." --: $item => $result\n";
	}
}

sub testToolRemoveLinear
{
    my @paths;
    #push @paths, "/home/lieryufeng/self/program/Self_Project/JavaToCplus_by_pm/External";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/net";
    #push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Interpolators";
    ToolRemoveLinear::removeLinearInFiles(\@paths);
}

sub testToolReplaceTab
{
    my @paths;
    #push @paths, "/home/lieryufeng/self/program/Self_Project/JavaToCplus_by_pm/External";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/net";
    #push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Interpolators";
    ToolReplaceTab::replaceTabInFiles(\@paths);
}

sub testToolModifyNoteInAddBrackets
{
    my @paths;
    push @paths, "/home/lieryufeng/self/program/Self_Project/JavaToCplus_by_pm/External";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
    push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    ToolModifyNoteInAddBrackets::modifyNoteInAddBracketsWithPaths(\@paths);
}

sub testFileTag
{
    my $value = $FileTag::DC_astart;
    my $ts = $FileTag::K_NodeType;
    print __LINE__." value=$value, \$ts=$ts\n";
}

sub testToolCheckObviousError
{
    my @filesPath;
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/net";

    my $filesPaths = FileOperate::readDirs(\@filesPath);
    my $ret = ToolcheckObviousError::checkObviousErrorInFiles($filesPaths);
}

sub testToolModifyMacro
{
    my @filesPath;
    #push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Interpolators";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";

    my @exceptsPath;
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Base";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Autofill";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Gfx";

    my @empty;
    ToolModifyMacro::modifyMacroWithPathsAndExcepts(\@filesPath, \@empty, ".h");
}

sub testToolBuildSourceFile
{
	my $dirPath = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/components";
	ToolBuildSourceFile::buildSource($dirPath);
}

sub testQE
{
    my $tmp = "hab/fjdlj/kkk.h";
    my $endPrefix = ".h";
    if ($tmp =~ m/\Q$endPrefix\E$/) {
        print __LINE__." match\n";
    }
    else {
        print __LINE__." no match\n";
    }
}

sub testBuildNamespace
{
    my @namespaces;
    push @namespaces, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/content/browser";
    push @namespaces, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    push @namespaces, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";

    my $results = BuildNamespace::buildNamespaces(\@namespaces);
    my $resultLine = join "\n", @$results;
    print __LINE__." \$resultLine=\n$resultLine\n";
}

sub testBuildMarco
{
    my @namespaces;
    push @namespaces, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/content/browser/fileA.h";
    push @namespaces, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net/fileB.h";
    push @namespaces, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/fileC.h";

    my $results = BuildMarco::buildMacros(\@namespaces);
    my $resultLine = join "\n", @$results;
    print __LINE__." \$resultLine=\n$resultLine\n";
}

sub testFileOperate
{
    my @wrData;
    push @wrData, "hahahaha\n";
    push @wrData, "test";
    FileOperate::writeFile("./tmp.bak", \@wrData);
    my $readData = FileOperate::readFile("./tmp.bak");
    my $dataLine = join "", @$readData;
    print __LINE__." \$dataLine=\n$dataLine\n";

    my @filesPath;
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui";
    push @filesPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";

    my @exceptsPath;
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Base";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Autofill";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
    push @exceptsPath, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui/Gfx";
    my $retfilesPath = FileOperate::readDirsAndExcepts(\@filesPath, \@exceptsPath, ".h");
    my $filesLine = join "\n", @$retfilesPath;
    print __LINE__." \$filesLine=\n$filesLine\n";
}

sub testReg
{
	my $input = "// Copyright 2012 The Chromium Authors. All rights reserved.\n";
	$input = $input."// Copyright 2012 The Chromium Authors. All rights reserved.\n";
	if ($input =~ m/^(\/\/.*)$/) {
		print "match\n";
	}
	else {
		print "no match\n";
	}
}

sub testFunc
{
	#my $path = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/webkit/native/ui/ColorPickerDialog.h";
    #my $doc = FileAnalysisC_doth::analysisC_doth($path);
    #$doc->testOutputStruct("    ");
    #FileAnalysisC_doth::obtAllClassPathInDoth($path);

    my $lastSub = Util::getSplitSubStr("AAA/BBB/CCC", "/", -1);
    print __LINE__." \$lastSub=$lastSub\n";
}

sub testMachReg
{
	my $old = "R.string.color_picker_saturation, SATURATION_SEEK_BAR_MAX(ArrayOf<Map, kk>, 1), this";
	my $subs = Util::stringSplitParamsContent($old);
	foreach (@$subs) {
		print __LINE__." param: [$_]\n";
	}
}

sub testSortStr
{
	my @subs = ();
	push @subs, "#include \"elastos/droid/webkit/native/android_webview/AwCookieManager.h\"";
	push @subs, "#include \"elastos/droid/ext/frameworkext.h\"";
	push @subs, "#include \"elastos/droid/net/WebAddress.h\"";
	push @subs, "#include \"elastos/droid/webkit/CookieManager.h\"";
	print __LINE__."before sort:\n";
	my $output = join "\n", @subs;
	print $output."\n";

	@subs = sort @subs;
	print __LINE__."after sort:\n";
	$output = join "\n", @subs;
	print $output."\n";
}

sub testModifyIncludeUsing
{
	my @paths = ();
=pod
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/webview/chromium";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/webview/chromium";

	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/components";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/components";

	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/net";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/net";

	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/webkit/native/ui";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/ui";
	ToolModifyIncludeUsingSort::modifySortIncludeUsingWithPaths(\@paths);
=cut

	push @paths, "/home/lieryufeng/self/program/__svn__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/widget/Chronometer.h";
	push @paths, "/home/lieryufeng/self/program/__svn__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/elastos/droid/widget/CChronometer.h";

	push @paths, "/home/lieryufeng/self/program/__svn__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/widget/Chronometer.cpp";
	push @paths, "/home/lieryufeng/self/program/__svn__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/widget/CChronometer.cpp";

	ToolModifyIncludeUsingSort::doModifySortIncludeUsing(\@paths);
}

sub testSplice
{
	my @src = ();
	push @src, "AAAAAAAAAAAAAAAAAAAAA\n";
	push @src, "AAAAAAAAAAAAAAAAAAAAA1\n";
	push @src, "AAAAAAAAAAAAAAAAAAAAA2\n";
	push @src, "AAAAAAAAAAAAAAAAAAAAA3\n";
	push @src, "AAAAAAAAAAAAAAAAAAAAA4\n";
	push @src, "AAAAAAAAAAAAAAAAAAAAA5\n";
	push @src, "AAAAAAAAAAAAAAAAAAAAA6\n";

	my @insert = ();
	push @insert, "BBB\n";
	push @insert, "BBB1\n";

	splice (@src, 2, 2, @insert);
	print @src;
}

sub testFindLeftAutoPtrWhenProbe
{
	my @paths = ();
	print __LINE__." testFindLeftAutoPtrWhenProbe\n";

	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/webview/chromium";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/components";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/net";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/ui";
	ToolFindLeftAutoPtrWhenProbe::findLeftAutoPtrWhenProbeWithPaths(\@paths);
}

sub testFindLoggerString
{
	my @paths = ();
	print __LINE__." testFindLoggerString\n";

	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/webview/chromium";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/components";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/net";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/ui";
	ToolFindLogString::findLogStringWithPaths(\@paths);
}

sub testFindProbeIInterface
{
	my @paths = ();
	print __LINE__." testFindProbeIInterface\n";

	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/webview/chromium";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/components";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/net";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/ui";
	ToolFindProbeIInterface::findProbeIInterfaceWithPaths(\@paths);
}

sub testFindThisProbe
{
	my @paths = ();
	print __LINE__." testFindThisProbe\n";

	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/webview/chromium";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/components";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/net";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/ui";
	ToolFindThisProbe::findThisProbeWithPaths(\@paths);
}

sub testFindOutParamHasRefAdd
{
	my @paths = ();
	print __LINE__." testFindOutParamHasRefAdd\n";

	# test: push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/wuweizuo_test_Base/Core/inc/elastos/droid/webkit/native";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/webview/chromium";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/components";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/net";
	push @paths, "/home/lieryufeng/self/program/__work__/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/elastos/droid/webkit/native/ui";
	ToolFindOutParamHasRefAdd::findOutParamHasRefAddWithPaths(\@paths);
}

