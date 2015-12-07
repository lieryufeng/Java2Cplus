#!/usr/bin/perl;

package TransElastosType;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use warnings;
use ToolDealImports;

my @gSameLayerFileNames = ();


sub isCarType
{
	my $type = shift;
	my $dstCarTypePtr = shift;
	return ToolDealImports::isImportTypeIsCar($type, $dstCarTypePtr);
}

sub isCommonType
{
	my $type = shift;
	if ("String" eq $type) {
		return 1;
	}
	elsif ("Int32" eq $type || "Int64" eq $type || "int" eq $type || "long" eq $type) {
		return 1;
	}
	elsif ("Float" eq $type || "Double" eq $type || "float" eq $type || "double" eq $type) {
		return 1;
	}
	elsif ("Boolean" eq $type || "boolean" eq $type) {
		return 1;
	}
	elsif ("Byte" eq $type || "byte" eq $type) {
		return 1;
	}
	elsif ("Char8" eq $type) {
		return 1;
	}
	return 0;
}

sub isAutoPtr
{
	my $type = shift;
	if ($type =~ m/^AutoPtr</) { return 1; }
	return 0;
}

sub isArrayOf
{
	my $type = shift;
	if ($type =~ m/^ArrayOf</) { return 1; }
	return 0;
}

sub isPointer
{
	my $type = shift;
	if ($type =~ m/\*$/) { return 1; }
	return 0;
}

sub setSameLayerFileNames
{
	my $sameLayerFileNames = shift;
	@gSameLayerFileNames = @$sameLayerFileNames;
}

sub transParClassElastosType
{
	my $root = shift;
	my $srcType = shift;
	my $additionJavaPath = shift; # may be not exist
	my $dstType = "";
	# for java
	# may has more sub like as AAA.BBB, AAA::BBB
	if ($srcType =~ m/\./ || $srcType =~ m/::/) {
		# temp
		$dstType = $srcType;
		$dstType =~ s/\./::/;
		return $dstType;

		print __LINE__."\n ==============trans: $srcType\n";

		my $tryClassPath = $srcType;
		$tryClassPath =~ s/::/\./;
		$tryClassPath =~ s/\./\//;
		if (1 eq FileAnalysisJavaOnlyClass::chkClassPathisInJavaFileNode($root, \$tryClassPath)) {
			if (defined($additionJavaPath)) {
				if ($additionJavaPath =~ m/\/org\/chromium\//) {
					$dstType = $srcType;
					$dstType =~ s/\./::/;
				}
				else {
					$dstType = $srcType;
					$dstType =~ s/\.//;
					$dstType = "I".$dstType;
				}
				return $dstType;
			}
			return "";
		}

		# first get import str
		$srcType =~ s/::/\./;
		my @subs = split(/\./, $srcType);
		my $firstWord = $subs[0];
		my $importStr = FileAnalysisJavaNoFunc::getImportStrBySpecifyEnd($root, $firstWord);
		print __LINE__." get Import by $firstWord\n";
		if ("" eq $importStr) {
			print __LINE__." $srcType cannot find importstr corresponding\n";
			#<STDIN>;
			return "";
		}

		# find java file by import str
		my ($find, $javaPath) = AndroidFilePathTry::obtImportStr2JavaPath($importStr);
		print __LINE__." obt java path: $javaPath\n";
		if (0 eq $find) {
			print __LINE__." cannot find java file by import: $importStr\n";
			#<STDIN>;
			return "";
		}

		# analysis java file to find whole class path define
		# find whole class path, determine target name according to the class path
		my $classPath = join "/", @subs;
		print __LINE__." \$classPath=$classPath\n";
		if (1 eq FileAnalysisJavaOnlyClass::chkClassPathisInJavaPath($javaPath, \$classPath)) {
			$importStr =~ s/^import\s+//;
			if ($importStr =~ m/^org\./) {
				my @tmps = split(/\//, $classPath);
				$dstType = join "::", @tmps;
			}
			else {
				my @tmps = split(/\//, $classPath);
				my $tmp = join "", @tmps;
				$dstType = "I".$tmp;
			}
			print __LINE__." class find, \$dstType=$dstType\n";
			return $dstType;
		}

		# if class path is not in java path
		# it may be in its parents, analysis it
		my $parDoc = FileAnalysisJavaOnlyClass::analysisFile($javaPath);
		#print __LINE__." analysis: $javaPath\nits format is follows:\n";
		$parDoc->testOutputStruct("");
		my $mainClassNode = $parDoc->getMainClassOrInterface;
		if (!defined($mainClassNode)) {
			<STDIN>;
		}
		my $parents = $mainClassNode->{ $FileTag::K_Parents };
		my $findWhat = "";
		# first need find parent class's java file, this need import str.
		# find parent class, find what == "ParentClass.CurrReaminSubs"
		# like as: need find "Dialog.OnClickListener"
		# so first find in Dialog.java but donot found, then find its parents
		# foreach parents, its first parent is "DialogInterface", second is "Window.Callback" ...
		# so need find new is "DialogInterface.OnClickListener", "Window.Callback.OnClickListener"
		my $remainCont = join ".", @subs;
		my @packages = ();
		my @imports = ();
		ToolDealImports::analysisNodeImports($parDoc, \@packages, \@imports);
		my $parentFirstWord = "";
		foreach my $parent (@$parents) {
			if ($parent =~ m/^(\w+|\d+)/) {
				$parentFirstWord = $1;
			}

			# parent type is not in imports, check same layers
			#my $importStr = join ", ", @imports;
			print __LINE__." \$parentFirstWord=$parentFirstWord\n";
			my $machImportStr = "";
			if (0 eq ToolDealImports::isOneOfSpecipyImports(\@imports, $parentFirstWord, \$machImportStr)) {
				$findWhat = $parent.".$remainCont";;
				print __LINE__." cannot find type in imports, may be in same layer?, \$findWhat=$findWhat\n";
				my $dstTypeTmp = &transSameLayerClassElastosTypeAdditPath($javaPath, $findWhat, $srcType);
				print __LINE__." transParType, \$dstTypeTmp=$dstTypeTmp\n";
				if ("" ne $dstTypeTmp) {
					$dstType = $dstTypeTmp;
					return $dstType;
				}
				print __LINE__." cannot find type in same layer, is that right?\n";
				<STDIN>;
			}

			# check parent
			print __LINE__." isOneOfSpecifyImport, \$machImportStr=$machImportStr\n";
			my ($parFind, $parPath) = AndroidFilePathTry::obtImportStr2JavaPath($machImportStr);
			if (0 eq $parFind) {
				print __LINE__." cannot find specify java file by import str\n";
				<STDIN>;
			}
			print __LINE__." obtParJavaPath, \$parPath=$parPath\n";
			my $doc = FileAnalysisJavaOnlyClass::analysisFile($parPath);
			$findWhat = $parent.".$remainCont";
			#print __LINE__." before into next find loop, \$findWhat=$findWhat\n";
			my $dstTypeTmp = &transParClassElastosTypeAdditPath($doc, $findWhat, $parPath);
			print __LINE__." transParType, \$dstTypeTmp=$dstTypeTmp\n";
			if ("" ne $dstTypeTmp) {
				$dstType = $dstTypeTmp;
				return $dstType;
			}
		}
		return "";
	}
	if (1 eq ToolDealImports::isImportType($srcType, \$dstType)) {
		return $dstType;
	}
	if ($srcType !~ m/\./ && $srcType !~ m/::/ && 1 eq &isCarType($srcType)) {
		return "I".$srcType;
	}
	return $srcType;
}

sub transParClassElastosTypeAdditPath
{
	my $root = shift;
	my $srcType = shift;
	my $additionalJavaPath = shift;
	my $dstType = "";
	# for java
	# may has more sub like as AAA.BBB, AAA::BBB
	if ($srcType =~ m/\./ || $srcType =~ m/::/) {
		$srcType =~ s/::/\./;
		# special situation, check curr file class path whether equal srcType
		my $classPathTmp = $srcType;
		$classPathTmp =~ s/\./\//;
		if (1 eq FileAnalysisJavaOnlyClass::chkClassPathisInJavaFileNode($root, \$classPathTmp)) {
			if (defined($additionalJavaPath)) {
				 if ($additionalJavaPath =~ m/\/org\/chromium\//) {
					$dstType = $srcType;
					$dstType =~ s/\./::/;
				 }
				 else {
					$dstType = $srcType;
					$dstType =~ s/\.//;
					$dstType = "I".$dstType;
				 }
				 return $dstType;
			}
			# default
			$dstType = $srcType;
			$dstType =~ s/\./::/;
			return $dstType;
		}

		my @subs = split(/\./, $srcType);
		my $firstWord = shift @subs;
		my $importStr = FileAnalysisJavaNoFunc::getImportStrBySpecifyEnd($root, $firstWord);
		print __LINE__." get Import by $firstWord\n";
		if ("" eq $importStr) {
			print __LINE__." $srcType cannot find importstr corresponding\n";
			#<STDIN>;
			return "";
		}
		# find java file by import str
		my ($find, $javaPath) = AndroidFilePathTry::obtImportStr2JavaPath($importStr);
		print __LINE__." obt java path: $javaPath\n";
		if (0 eq $find) {
			print __LINE__." cannot find java file by import: $importStr\n";
			#<STDIN>;
			return "";
		}
		# analysis java file to find whole class path define
		# find whole class path, determine target name according to the class path
		my $classPath = join "/", @subs;
		print __LINE__." \$classPath=$classPath\n";
		if (1 eq FileAnalysisJavaOnlyClass::chkClassPathisInJavaPath($javaPath, \$classPath)) {
			$importStr =~ s/^import\s+//;
			if ($importStr =~ m/^org\./) {
				my @tmps = split(/\//, $classPath);
				$dstType = join "::", @tmps;
			}
			else {
				my @tmps = split(/\//, $classPath);
				my $tmp = join "", @tmps;
				$dstType = "I".$tmp;
			}
			print __LINE__." class find, \$dstType=$dstType\n";
			return $dstType;
		}
		# if class path is not in java path
		# it may be in its parents, analysis it
		my $doc = FileAnalysisJavaOnlyClass::analysisFile($javaPath);
		print __LINE__." analysis: $javaPath\nits format is follows:\n";
		$doc->testOutputStruct("");
		my $mainClassNode = $doc->getMainClassOrInterface;
		if (!defined($mainClassNode)) {
			<STDIN>;
		}
		my $parents = $mainClassNode->{ $FileTag::K_Parents };
		my $findWhat = "";
		# first need find parent class's java file, this need import str.
		# find parent class, find what == "ParentClass.CurrReaminSubs"
		# like as: need find "Dialog.OnClickListener"
		# so first find in Dialog.java but donot found, then find its parents
		# foreach parents, its first parent is "DialogInterface", second is "Window.Callback" ...
		# so need find new is "DialogInterface.OnClickListener", "Window.Callback.OnClickListener"
		my $remainCont = join ".", @subs;
		my @packages = ();
		my @imports = ();
		ToolDealImports::analysisNodeImports($doc, \@packages, \@imports);
		my $parentFirstWord = "";
		foreach my $parent (@$parents) {
			if ($parent =~ m/^(\w+|\d+)/) {
				$parentFirstWord = $1;
			}
			#my $importStr = join ", ", @imports;
			#print __LINE__." \$importStr=$importStr, \$parentFirstWord=$parentFirstWord\n";
			my $machImportStr = "";
			if (0 eq ToolDealImports::isOneOfSpecipyImports(\@imports, $parentFirstWord, \$machImportStr)) {
				print __LINE__." cannot find type in imports, may be in same layer?\n";
				<STDIN>;
			}
			print __LINE__." isOneOfSpecifyImport, \$machImportStr=$machImportStr\n";
			my ($parFind, $parPath) = AndroidFilePathTry::obtImportStr2JavaPath($machImportStr);
			if (0 eq $find) {
				print __LINE__." cannot find specify java file by import str\n";
				<STDIN>;
			}
			print __LINE__." obtParJavaPath, \$parPath=$parPath\n";
			my $doc = FileAnalysisJavaOnlyClass::analysisFile($parPath);
			$findWhat = $parent.".$remainCont";
			#print __LINE__." before into next find loop, \$findWhat=$findWhat\n";
			my $dstTypeTmp = &transParClassElastosTypeAdditPath($doc, $findWhat, $parPath);
			print __LINE__." transParType, \$dstTypeTmp=$dstTypeTmp\n";
			if ("" ne $dstTypeTmp) {
				$dstType = $dstTypeTmp;
				return $dstType;
			}
		}
		return "";
	}
	return $srcType;
}

sub transSameLayerClassElastosTypeAdditPath
{
	my $javaPath = shift;
	my $currFindWhat = shift;
	my $mostOldSrcType = shift;
	my $dstType = "";
	my $srcFirstWord = "";
	print __LINE__." into transSameLayerClassElastosTypeAdditPath, \$mostOldSrcType=$mostOldSrcType, \$currFindWhat=$currFindWhat\n";
	if ($currFindWhat =~ m/^(\w+|\d+)/) { $srcFirstWord = $1; }
	print __LINE__." \$srcFirstWord=$srcFirstWord\n";
	my $sameLayerJavaPaths = FileOperate::getFilePathsByFileSameLayer($javaPath, ".java");
	my $nameNoEndPrefix = "";
	my $isMachPath = 0;
	my $machPath = "";
	foreach my $path (@$sameLayerJavaPaths) {
		$nameNoEndPrefix = Util::getFileNameNoEndPrefixByPath($path);
		if ($nameNoEndPrefix eq $srcFirstWord) {
			$isMachPath = 1;
			$machPath = $path;
			last;
		}
	}

	print __LINE__." \$isMachPath=$isMachPath, \$machPath=$machPath\n";
	if (0 eq $isMachPath) {
		print __LINE__." can not find $srcFirstWord in same layers\n";
		<STDIN>;
		return "";
	}

	my $doc = FileAnalysisJavaOnlyClass::analysisFile($machPath, 1);
	print __LINE__." show its format:\n";
	$doc->testOutputStruct("");

	$currFindWhat =~ s/::/\./;
	my @subs = split(/\./, $currFindWhat);
	my $classPath = join "/", @subs;
	print __LINE__." \$classPath=$classPath\n";
	if (1 eq FileAnalysisJavaOnlyClass::chkClassPathisInJavaPath($machPath, \$classPath)) {
		if ($machPath =~ m/\/org\/chromium\//) {
			$dstType = $currFindWhat;
			$dstType =~ s/\./::/;
		}
		else {
			$dstType = $currFindWhat;
			$dstType =~ s/\.//;
			$dstType = "I".$dstType;
		}
		return $dstType;
	}

	my $mainClassNode = $doc->getMainClassOrInterface;
	if (!defined($mainClassNode)) {
		<STDIN>;
	}
	my $parents = $mainClassNode->{ $FileTag::K_Parents };
	my $findWhat = "";
	pop @subs;
	my $remainCont = join ".", @subs;
	my @packages = ();
	my @imports = ();
	ToolDealImports::analysisNodeImports($doc, \@packages, \@imports);
	my $parentFirstWord = "";
	foreach my $parent (@$parents) {
		if ($parent =~ m/^(\w+|\d+)/) {
			$parentFirstWord = $1;
		}
		print __LINE__." \$parentFirstWord=$parentFirstWord\n";
		my $machImportStr = "";
		if (0 eq ToolDealImports::isOneOfSpecipyImports(\@imports, $parentFirstWord, \$machImportStr)) {
			$findWhat = $parent.".$remainCont";;
			print __LINE__." cannot find type in imports, may be in same layer?, \$findWhat=$findWhat\n";
			my $dstTypeTmp = &transSameLayerClassElastosTypeAdditPath($javaPath, $findWhat, $mostOldSrcType);
			print __LINE__." transParType, \$dstTypeTmp=$dstTypeTmp\n";
			if ("" ne $dstTypeTmp) {
				$dstType = $dstTypeTmp;
				return $dstType;
			}
			print __LINE__." cannot find type in same layer, is that right?\n";
			<STDIN>;
		}

		print __LINE__." isOneOfSpecifyImport, \$machImportStr=$machImportStr\n";
		my ($parFind, $parPath) = AndroidFilePathTry::obtImportStr2JavaPath($machImportStr);
		if (0 eq $parFind) {
			print __LINE__." cannot find specify java file by import str\n";
			<STDIN>;
		}
		print __LINE__." obtParJavaPath, \$parPath=$parPath, \$mostOldSrcType=$mostOldSrcType\n";
		my $doc = FileAnalysisJavaOnlyClass::analysisFile($parPath, 1);
		#$doc->testOutputStruct("");
		@subs = split(/\./, $mostOldSrcType);
		shift @subs;
		$remainCont = join ".", @subs;
		$findWhat = $parent.".$remainCont";
		print __LINE__." before into next find loop, \$findWhat=$findWhat\n";
		my $dstTypeTmp = &transParClassElastosTypeAdditPath($doc, $findWhat, $parPath);
		print __LINE__." transParType, \$dstTypeTmp=$dstTypeTmp\n";
		if ("" ne $dstTypeTmp) {
			$dstType = $dstTypeTmp;
			return $dstType;
		}
	}
	print __LINE__." transSameLayerClassElastosTypeAdditPath nothing mach\n";
	return "";
}

sub transComplexVarDefineElastosType
{
	my $srcType = shift;
	my $dotHorCpp = shift;
	my $subs = Util::splitComplexDataType($srcType);
	my @res;
	my $tmp = "";
	foreach (@$subs) {
		$tmp = &doTransVarElastosType($_, $dotHorCpp, 0, 1);
		push @res, $tmp;
	}
	my $result = join " ", @res;
	return $result;
}

sub transComplexParamElastosType
{
	my $srcType = shift;
	my $dotHorCpp = shift;

	$srcType =~ s/final//;
	$srcType =~ s/const//;
	#print __LINE__."\n";
	#print __LINE__." into transComplexParamElastosType: \$srcType=[$srcType]\n";
	my $subs = Util::splitComplexDataType($srcType);
	my @res;
	my $tmp = "";
	foreach (@$subs) {
		#print __LINE__." $_ => ";
		$tmp = &doTransParmElastosType($_, $dotHorCpp, 0, 1);
		#print $tmp."\n";
		push @res, $tmp;
	}
	my $result = join " ", @res;

	# special deal, if result is "const XXX", translate it to "const XXX&"
	if ($result =~ m/^const\s+(\S+)$/ && $result !~ m/^const\s+(\S+?)\*$/) {
		my $name = $1;
		$result = "const $name&";
	}

	#print __LINE__." out transComplexParamElastosType: \$result=[$result]\n";
	#print __LINE__."\n";
	return $result;
}

sub transComplexReturnElastosType
{
	my $srcType = shift;
	my $dotHorCpp = shift;

	#print __LINE__."\n";
	#print __LINE__." into transComplexReturnElastosType: \$srcType=[$srcType]\n";
	my $subs = Util::splitComplexDataType($srcType);
	my @res;
	my $tmp = "";
	foreach (@$subs) {
		$tmp = &doTransRetElastosType($_, $dotHorCpp, 0, 1);
		push @res, $tmp;
	}
	my $result = join " ", @res;
	#print __LINE__." out transComplexReturnElastosType: \$result=[$result]\n";
	#print __LINE__."\n";
	return $result;
}

sub transOutParamElastosType
{
	my $srcType = shift;
	my $dotHorCpp = shift;
	my $result;

	if ($srcType =~ m/^String$/i) {
		$result = "String*";
	}
	elsif ($srcType =~ m/^Int32$/i || $srcType =~ m/^Int$/i) {
		$result = "Int32*";
	}
	elsif ($srcType =~ m/^Int64$/i || $srcType =~ m/^Long$/i) {
		$result = "Int64*";
	}
	elsif ($srcType =~ m/^Float$/i) {
		$result = "Float*";
	}
	elsif ($srcType =~ m/^Double$/i) {
		$result = "Double*";
	}
	elsif ($srcType =~ m/^Boolean$/i) {
		$result = "Boolean*";
	}
	elsif ($srcType =~ m/^Byte$/i) {
		$result = "Byte*";
	}
	elsif ($srcType =~ m/^Char8$/i) {
		$result = "Char8*";
	}
	else {
		$result = "$srcType**";
	}
	return $result;
}

sub transComplexReturnExpress
{
	my $transRet = shift;
	my $startSpace = shift;
	my @contexts = ();

	# single type
	if ("ECode" eq $transRet) {
		push @contexts, $startSpace."return NOERROR;\n";
	}
	elsif ("String" eq $transRet) {
		push @contexts, $startSpace."return String(\"\");\n";
	}
	elsif ("Int32" eq $transRet || "Int64" eq $transRet) {
		push @contexts, $startSpace."return 0;\n";
	}
	elsif ("Float" eq $transRet || "Double" eq $transRet) {
		push @contexts, $startSpace."return 0.0f;\n";
	}
	elsif ("Boolean" eq $transRet) {
		push @contexts, $startSpace."return FALSE;\n";
	}
	elsif ("Byte" eq $transRet) {
		push @contexts, $startSpace."return 0;\n";
	}
	elsif ("Char8" eq $transRet) {
		push @contexts, $startSpace."return 0;\n";
	}
	# complex type
	elsif ($transRet =~ m/^AutoPtr<.*?>$/) {
		push @contexts, $startSpace."$transRet empty;\n";
		push @contexts, $startSpace."return empty;\n";
	}
	elsif ("" eq $transRet) {
		# nothing
	}
	else {
		print __LINE__." transComplexReturnExpress into else, check it, \$transRet=[$transRet]\n";
		<STDIN>;
	}

	return \@contexts;
}

sub doTransVarElastosType
{
	my $srcType = shift;
	my $dotHorCpp = shift;
	my $transLoopLayer = shift; # start with 0
	my $isSingleComplete = shift;
	$srcType = Util::stringTrim($srcType);
	my $result = "";
	my $dstTypeTmp = "";

	# single equal
	if ("int" eq $srcType) {
		$result = "Int32";
	}
	elsif ("long" eq $srcType) {
		$result = "Int64";
	}
	elsif ("float" eq $srcType) {
		$result = "Float";
	}
	elsif ("double" eq $srcType) {
		$result = "Double";
	}
	elsif ("boolean" eq $srcType) {
		$result = "Boolean";
	}
	elsif ("String" eq $srcType) {
		$result = "String";
	}
	elsif ("final" eq $srcType) {
		$result = "const";
	}
	elsif ("byte" eq $srcType) {
		$result = "Byte";
	}
	elsif ("char" eq $srcType) {
		$result = "Char8";
	}
	elsif (1 eq ToolDealImports::isImportType($srcType, \$dstTypeTmp)) {
		if (0 == $transLoopLayer) { $result = "AutoPtr<$dstTypeTmp>"; }
		else { $result = "$dstTypeTmp"; }
	}
	# in current package
	elsif (1 eq Util::isOneOfArray(\@gSameLayerFileNames, $srcType)) {
		if (0 == $transLoopLayer) { $result = "AutoPtr<$srcType>"; }
		else { $result = "$srcType"; }
	}

	# complex match
	# special format, do complete inner class temp.
	elsif ($srcType =~ m/^(\w+\*)/) {
		$result = $srcType;
		my $reaminContext = Util::stringTrim(substr($srcType, length($_)));
		if ("" ne $reaminContext) {
			my $subTransType2 = &doTransVarElastosType($reaminContext, $dotHorCpp, $transLoopLayer+1, 0);
			$result = &contextLinePlus($result, $subTransType2);
		}
	}
	# XXX<?>, java template, it isnot exist in car
	elsif ($srcType =~ m/^(\w+)\s*?<\?>/) {
		my $subType1 = $1;
		$srcType =~ s/^(\w+)\s*?<\?>/$subType1/;
		return &doTransVarElastosType($srcType, $dotHorCpp, $transLoopLayer, $isSingleComplete);
	}
	elsif ($srcType =~ m/^(\w+)\s*?</) {
		my $subType1 = $1;
		my $subType2 = "";
		my $firstSharp = index($srcType, "<");
		my ($isFind, $endIdx) = Util::findBracketsEnd($srcType, 3, "->", 0);
		if (1 eq $isFind) {
			$subType2 = substr($srcType, $firstSharp + 1, $endIdx - $firstSharp - 1);
		}

		my $subTransType1 = &doTransVarElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 0);
		my $subTransType2 = &doTransVarElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 1);
		$result = Util::addSpecifySignLikeAutoPtr($subTransType2, "$subTransType1");
		$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");

		my $reaminContext = Util::stringTrim(substr($srcType, $endIdx+1));
		if ("" ne $reaminContext) {
			my $subTransType2 = &doTransVarElastosType($reaminContext, $dotHorCpp, $transLoopLayer+1, 0);
			$result = &contextLinePlus($result, $subTransType2);
		}
	}
	elsif ($srcType =~ m/^(\w+)\s*?\[(.*?)\]\s*\[(.*?)\]/) {
		my $subType1 = $1;
		my $reg = qr/^(\w+)\s*?\[(.*?)\]\s*\[(.*?)\]/;
		my $subType2 = Util::stringMoreRegSplice($srcType, "", $reg, "->", 0, 0, 0, -1);

		my $subTransType1 = &doTransVarElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
		my $subTransType2 = "";
		if ("" ne $subType2) {
			$subTransType2 = &doTransVarElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 0);
		}
		$result = Util::addSpecifySignLikeAutoPtr($subTransType1, "ArrayOf");
		$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");
		$result = Util::addSpecifySignLikeAutoPtr($result, "ArrayOf");
		$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");
		$result = &contextLinePlus($result, $subTransType2);
	}
	elsif ($srcType =~ m/^(\w+)\s*?\[(.*?)\]/) {
		my $subType1 = $1;
		my $reg = qr/^(\w+)\s*?\[(.*?)\]/;
		my $subType2 = Util::stringMoreRegSplice($srcType, "", $reg, "->", 0, 0, 0, -1);

		my $subTransType1 = &doTransVarElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
		my $subTransType2 = "";
		if ("" ne $subType2) {
			$subTransType2 = &doTransVarElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 0);
		}
		$result = Util::addSpecifySignLikeAutoPtr($subTransType1, "ArrayOf");
		$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");
		$result = &contextLinePlus($result, $subTransType2);
	}
	# inner sub line, like as: Map<"String, Map<Context,String> ">
	elsif ($srcType =~ m/^(\w+)\s*?(,.*)/) {
		my $subType1 = $1;
		my $subType2 = Util::stringTrim($2);
		my $subTransType1 = &doTransVarElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
		my $subTransType2 = &doTransVarElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 1);
		$result = &contextLinePlus($subTransType1, $subTransType2);
	}
	elsif ($srcType =~ m/^,/) {
		$srcType =~ s/^,//;
		$result = ", ";
		$result = $result.&doTransVarElastosType($srcType, $dotHorCpp, $transLoopLayer+1, 0);
	}
	else {
		if (0 eq $transLoopLayer) {
			$result = Util::addSpecifySignLikeAutoPtr("$srcType", "AutoPtr");
		}
		else {
			$result = $srcType;
		}
	}

	$result =~ s/\./::/;
	#print __LINE__." $srcType => $result\n";
	return $result;
}

sub doTransParmElastosType
{
	my $srcType = shift;
	my $dotHorCpp = shift;
	my $transLoopLayer = shift; # start with 0
	my $isSingleComplete = shift;
	$srcType = Util::stringTrim($srcType);
	my $result = "";
	my $dstTypeTmp = "";

	if (1 eq ToolDealImports::isImportType($srcType, \$dstTypeTmp)) {
		#print __LINE__." $srcType is a CAR type\n";
	}

	# single equal
	if ("int" eq $srcType) {
		$result = "Int32";
	}
	elsif ("long" eq $srcType) {
		$result = "Int64";
	}
	elsif ("float" eq $srcType) {
		$result = "Float";
	}
	elsif ("double" eq $srcType) {
		$result = "Double";
	}
	elsif ("boolean" eq $srcType) {
		$result = "Boolean";
	}
	elsif ("String" eq $srcType) {
		#if (1 == $isSingleComplete) { $result = "const String&*"; }
		#else { $result = "String"; }
		$result = "String";
	}
	elsif ("final" eq $srcType) {
		$result = "const";
	}
	elsif ("byte" eq $srcType) {
		$result = "Byte";
	}
	elsif ("char" eq $srcType) {
		$result = "Char8";
	}
	elsif (1 eq ToolDealImports::isImportType($srcType, \$dstTypeTmp)) {
		if (0 == $transLoopLayer) { $result = "$dstTypeTmp*"; }
		else { $result = "$dstTypeTmp"; }
	}
	# in current package
	elsif (1 eq Util::isOneOfArray(\@gSameLayerFileNames, $srcType)) {
		if (1 == $isSingleComplete) { $result = "$srcType*"; }
		else { $result = "$srcType"; }
	}

	# complex match
	# special format, do complete inner class temp.
	elsif ($srcType =~ m/^(\w+\*)/) {
		$result = $srcType;
		my $reaminContext = Util::stringTrim(substr($srcType, length($_)));
		if ("" ne $reaminContext) {
			my $subTransType2 = &doTransParmElastosType($reaminContext, $dotHorCpp, $transLoopLayer+1, 0);
			$result = &contextLinePlus($result, $subTransType2);
		}
	}
	# XXX<?>, java template, it isnot exist in car
	elsif ($srcType =~ m/^(\w+)\s*?<\?>/) {
		my $subType1 = $1;
		$srcType =~ s/^(\w+)\s*?<\?>/$subType1/;
		return &doTransParmElastosType($srcType, $dotHorCpp, $transLoopLayer, $isSingleComplete);
	}
	elsif ($srcType =~ m/^(\w+)\s*?<(.*?)>/) {
		my $subType1 = $1;
		my $subType2 = "";
		my $firstSharp = index($srcType, "<");
		my ($isFind, $endIdx) = Util::findBracketsEnd($srcType, 3, "->", 0);
		if (1 eq $isFind) {
			$subType2 = substr($srcType, $firstSharp + 1, $endIdx - $firstSharp - 1);
		}

		my $subTransType1 = &doTransParmElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 0);
		my $subTransType2 = &doTransParmElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 1);
		$result = Util::addSpecifySignLikeAutoPtr($subTransType2, "$subTransType1");
		if (0 eq $transLoopLayer) {
			$result = $result."*";
		}

		my $reaminContext = Util::stringTrim(substr($srcType, $endIdx+1));
		if ("" ne $reaminContext) {
			my $subTransType2 = &doTransParmElastosType($reaminContext, $dotHorCpp, $transLoopLayer+1, 0);
			$result = &contextLinePlus($result, $subTransType2);
		}
	}
	elsif ($srcType =~ m/^(\w+)\s*?\[(.*?)\]\s*\[(.*?)\]/) {
		my $subType1 = $1;
		my $reg = qr/^(\w+)\s*?\[(.*?)\]\s*\[(.*?)\]/;
		my $subType2 = Util::stringMoreRegSplice($srcType, "", $reg, "->", 0, 0, 0, -1);
		my $subTransType1 = &doTransParmElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
		my $subTransType2 = "";
		if ("" ne $subType2) {
			$subTransType2 = &doTransParmElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 0);
		}
		$result = Util::addSpecifySignLikeAutoPtr($subTransType1, "ArrayOf");
		$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");
		$result = Util::addSpecifySignLikeAutoPtr($result, "ArrayOf");
		if (0 eq $transLoopLayer) {
			$result = $result."*";
		}
		$result = &contextLinePlus($result, $subTransType2);
	}
	elsif ($srcType =~ m/^(\w+)\s*?\[(.*?)\]/) {
		my $subType1 = $1;
		my $reg = qr/^(\w+)\s*?\[(.*?)\]/;
		my $subType2 = Util::stringMoreRegSplice($srcType, "", $reg, "->", 0, 0, 0, -1);
		my $subTransType1 = &doTransParmElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
		my $subTransType2 = "";
		if ("" ne $subType2) {
			$subTransType2 = &doTransParmElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 0);
		}
		$result = Util::addSpecifySignLikeAutoPtr($subTransType1, "ArrayOf");
		if (0 eq $transLoopLayer) {
			$result = $result."*";
		}
		$result = &contextLinePlus($result, $subTransType2);
	}
	# inner sub line, like as: Map<"String, Map<Context,String> ">
	elsif ($srcType =~ m/^(\w+)\s*?(,.*)/) {
		my $subType1 = $1;
		my $subType2 = Util::stringTrim($2);
		my $subTransType1 = &doTransParmElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
		my $subTransType2 = &doTransParmElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 1);
		$result = &contextLinePlus($subTransType1, $subTransType2);
	}
	elsif ($srcType =~ m/^,/) {
		$srcType =~ s/^,//;
		$result = ", ";
		$result = $result.&doTransParmElastosType($srcType, $dotHorCpp, $transLoopLayer+1, 0);
	}
	else {
		if (1 == $isSingleComplete) { $result = "$srcType*"; }
		else { $result = "$srcType"; }
	}

	$result =~ s/\./::/;
	return $result;
}

sub doTransRetElastosType
{
	my $srcType = shift;
	my $dotHorCpp = shift;
	my $transLoopLayer = shift; # start with 0
	my $isSingleComplete = shift;
	$srcType = Util::stringTrim($srcType);
	my $result = "";
	my $dstTypeTmp = "";

	if ("void" eq $srcType) {
		if (0 eq $dotHorCpp) { $result = "CARAPI"; }
		else { $result = "ECode"; }
	}
	else {
		if ("int" eq $srcType) {
			$result = "Int32";
		}
		elsif ("long" eq $srcType) {
			$result = "Int64";
		}
		elsif ("float" eq $srcType) {
			$result = "Float";
		}
		elsif ("double" eq $srcType) {
			$result = "Double";
		}
		elsif ("boolean" eq $srcType) {
			$result = "Boolean";
		}
		elsif ("String" eq $srcType) {
			$result = "String";
		}
		elsif ("final" eq $srcType) {
			$result = "const";
		}
		elsif ("byte" eq $srcType) {
			$result = "Byte";
		}
		elsif ("char" eq $srcType) {
			$result = "Char8";
		}
		elsif (1 eq ToolDealImports::isImportType($srcType, \$dstTypeTmp)) {
			if (1 == $isSingleComplete) { $result = "AutoPtr<$dstTypeTmp>"; }
			else { $result = "$dstTypeTmp"; }
		}
		# in current package
		elsif (1 eq Util::isOneOfArray(\@gSameLayerFileNames, $srcType)) {
			if (1 == $isSingleComplete) { $result = "AutoPtr<$srcType>"; }
			else { $result = "$srcType"; }
		}

		# special format, do complete inner class temp.
		elsif ($srcType =~ m/^(\w+\*)/) {
			$result = &addAutoPtrSign($srcType);
			my $reaminContext = Util::stringTrim(substr($srcType, length($_)));
			if ("" ne $reaminContext) {
				my $subTransType2 = &doTransRetElastosType($reaminContext, $dotHorCpp, $transLoopLayer+1, 0);
				$result = &contextLinePlus($result, $subTransType2);
			}
		}
		# XXX<?>, java template, it isnot exist in car
		elsif ($srcType =~ m/^(\w+)\s*?<\?>/) {
			my $subType1 = $1;
			$srcType =~ s/^(\w+)\s*?<\?>/$subType1/;
			return &doTransRetElastosType($srcType, $dotHorCpp, $transLoopLayer, $isSingleComplete);
		}
		elsif ($srcType =~ m/^(\w+)\s*?<(.*?)>/) {
			my $subType1 = $1;
			my $subType2 = "";
			my $firstSharp = index($srcType, "<");
			my ($isFind, $endIdx) = Util::findBracketsEnd($srcType, 3, "->", 0);
			if (1 eq $isFind) {
				$subType2 = substr($srcType, $firstSharp + 1, $endIdx - $firstSharp - 1);
			}

			my $subTransType1 = &doTransRetElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 0);
			my $subTransType2 = &doTransRetElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 1);
			$result = Util::addSpecifySignLikeAutoPtr($subTransType2, "$subTransType1");
			$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");

			my $reaminContext = Util::stringTrim(substr($srcType, $endIdx+1));
			if ("" ne $reaminContext) {
				my $subTransType2 = &doTransParmElastosType($reaminContext, $dotHorCpp, $transLoopLayer+1, 0);
				$result = &contextLinePlus($result, $subTransType2);
			}
		}
		elsif ($srcType =~ m/^(\w+)\s*?\[(.*?)\]\s*\[(.*?)\]/) {
			my $subType1 = $1;
			my $reg = qr/^(\w+)\s*?\[(.*?)\]\s*\[(.*?)\]/;
			my $subType2 = Util::stringMoreRegSplice($srcType, "", $reg, "->", 0, 0, 0, -1);
			my $subTransType1 = &doTransRetElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
			my $subTransType2 = "";
			if ("" ne $subType2) {
				$subTransType2 = &doTransParmElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 0);
			}
			$result = Util::addSpecifySignLikeAutoPtr($subTransType1, "ArrayOf");
			$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");
			$result = Util::addSpecifySignLikeAutoPtr($result, "ArrayOf");
			$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");
			$result = &contextLinePlus($result, $subTransType2);
		}
		elsif ($srcType =~ m/^(\w+)\s*?\[(.*?)\]/) {
			my $subType1 = $1;
			my $reg = qr/^(\w+)\s*?\[(.*?)\]/;
			my $subType2 = Util::stringMoreRegSplice($srcType, "", $reg, "->", 0, 0, 0, -1);
			my $subTransType1 = &doTransRetElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
			my $subTransType2 = "";
			if ("" ne $subType2) {
				$subTransType2 = &doTransParmElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 0);
			}
			$result = Util::addSpecifySignLikeAutoPtr($subTransType1, "ArrayOf");
			$result = Util::addSpecifySignLikeAutoPtr($result, "AutoPtr");
			$result = &contextLinePlus($result, $subTransType2);

			#print __LINE__." mach []\n";
		}
		# inner sub line, like as: Map<"String, Map<Context,String> ">
		elsif ($srcType =~ m/^(\w+)\s*?(,.*)/) {
			my $subType1 = $1;
			my $subType2 = Util::stringTrim($2);
			my $subTransType1 = &doTransRetElastosType($subType1, $dotHorCpp, $transLoopLayer+1, 1);
			my $subTransType2 = &doTransRetElastosType($subType2, $dotHorCpp, $transLoopLayer+1, 1);
			$result = &contextLinePlus($subTransType1, $subTransType2);
		}
		elsif ($srcType =~ m/^,/) {
			$srcType =~ s/^,//;
			$result = ", ";
			$result = $result.&doTransRetElastosType($srcType, $dotHorCpp, $transLoopLayer+1, 0);
		}
		else {
			if (1 == $isSingleComplete) { $result = "AutoPtr<$srcType>"; }
			else { $result = $srcType; }
		}

		$result = &maybeAddCARAPISign($result, $dotHorCpp, $transLoopLayer);
	}

	$result =~ s/\./::/;
	return $result;
}

sub obtUsefullType
{
	my $type = shift;
	$type =~ s/\s*static\*//;
	$type =~ s/\s*const\*//;
	$type =~ s/\s*final\*//;
	return $type;
}

sub maybeAddCARAPISign
{
	my $type = shift;
	my $dotHorCpp = shift;
	my $layer = shift;
	my $newType = $type;
	if (0 eq $layer && 0 eq $dotHorCpp) {
		$newType = Util::addCARAPI_Sign($type);
	}
	return $newType;
}

sub contextLinePlus
{
	my $type = shift;
	my $append = shift;
	if ($append =~ m/^\w|\d/) {
		$type = $type." ".$append;
	}
	else {
		$type = $type.$append;
	}
	return $type;
}


1;
