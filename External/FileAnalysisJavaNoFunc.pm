#!/usr/bin/perl;

package FileAnalysisJavaNoFunc;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( analysisFiles  analysisFile );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;
use TransElastosType;
use ToolDealImports;
use AndroidFilePathTry;
#use FileAnalysisJavaFuncContent;

my $gAnalysisFuncContent = 0;
my $gAnalysisNoNameClass = 0;
my $gObtAllJavaPathsYet = 0;
my $gAnalysisCurrRoot;

sub analysisFiles
{
	# obtain all java files path in android base dir
	if (0 eq $gObtAllJavaPathsYet) {
		#$gObtAllJavaPathsYet = 1;
		#AndroidFilePathTry::obtAllJavaFilePaths;
	}

	my $currJavaPaths = shift;
	my $analysisFuncContent = shift;
	my $anslysisNoNameClass = shift;
	my @docs;
    foreach my $path (@$currJavaPaths) {
        push @docs, &analysisFile($path, $analysisFuncContent, $anslysisNoNameClass);
    }
    return \@docs;
}

sub analysisFile
{
	my $currJavaPath = shift;
	my $analysisFuncContent = shift;
	my $anslysisNoNameClass = shift;

	# obtain all java files path in android base dir
	if (0 eq $gObtAllJavaPathsYet) {
		#$gObtAllJavaPathsYet = 1;
		#AndroidFilePathTry::obtAllJavaFilePaths;
	}

	# init before analysis
	if (defined($analysisFuncContent) && 1 eq $analysisFuncContent) {
		$gAnalysisFuncContent = 1;
	}
	else {
		$gAnalysisFuncContent = 0;
	}

	if (defined($anslysisNoNameClass) && 1 eq $anslysisNoNameClass) {
		$gAnalysisNoNameClass = 1;
	}
	else {
		$gAnalysisNoNameClass = 0;
	}

	my $sameLayoutFileNames = FileOperate::getFileNamesByFileSameLayer($currJavaPath, ".java");
	TransElastosType::setSameLayerFileNames($sameLayoutFileNames);

	# analysis
	print __LINE__." analysis: $currJavaPath\n";
	# analysid import alone
    ToolDealImports::resetImportInfo;
	ToolDealImports::analysisFileImportInfos($currJavaPath);

   	my $javaDataLines = FileOperate::readFile($currJavaPath);
   	my $javaDataContext = join " ", @$javaDataLines;
    my $doc = createRootNode FileAnalysisStruct($currJavaPath);
    $gAnalysisCurrRoot = $doc;
   	&analysisContext($javaDataContext, $doc);
   	return $doc;
}

sub analysisContext
{
   	my $remainDataContext = shift;
   	my $parNode = shift;

    while (1) {
    	my ($remainDataTmp, $tag, $machSub) = &analysisCurrTag($remainDataContext, $parNode);
    	$remainDataContext = $remainDataTmp;
		#my $strTag = FileTag::getTagString($tag);
		#print "--tag=[$strTag], mach_str=[$machSub]\n";
		#sleep 1;
		if (FileTag::isTagValid($tag)) {
			my $newNode = new FileAnalysisStruct;
			$newNode->{ $FileTag::K_NodeTag } = $tag;
			$newNode->{ $FileTag::K_ParNode } = $parNode;
			$parNode->appendChildNode( $newNode );

			if ($FileTag::DC_empty eq $tag) {
	    		&analysisEmpty($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_package eq $tag) {
	    		&analysisPackage($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_import eq $tag) {
	    		&analysisImport($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_astart eq $tag) {
	    		&analysisAStart($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_note eq $tag) {
	    		&analysisNote($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_class eq $tag) {
	    		&analysisClass($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_interface eq $tag) {
	    		&analysisInterface($tag, $machSub, $parNode, $newNode);
	    	}
			elsif ($FileTag::DC_function_define eq $tag) {
	    		&analysisFuncDefine($tag, $machSub, $parNode, $newNode);
	    	}
			elsif ($FileTag::DC_function_call eq $tag) {
	    		&analysisFuncCall($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_var_define eq $tag) {
	    		&analysisVarDefine($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_var_assignment eq $tag) {
	    		&analysisVarAssignment($tag, $machSub, $parNode, $newNode);
	    	}
	    	else {
	    		print __LINE__."[E] \$DC var match failed.\n";
	    	}
		}
		else {
		}

    	if ("" eq $remainDataContext) {
    		last;
    	}
    }
}

sub analysisEmpty
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "EMPTY";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = "\n";
}

sub analysisPackage
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "PACKAGE";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	if ($machSub !~ m/package\s+org\./) {
		$machSub =~ s/;//g;
		$machSub = Util::stringTrim($machSub);
		if ($machSub =~ m/\.(\w+)$/) {
			#TransElastosType::addCarType($1);
		}
	}
}

sub analysisImport
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "IMPORT";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;
}

sub analysisAStart
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "\@START";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;
}

sub analysisNote
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "NOTE";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;
}

sub analysisClass
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my ($className, $scope, $isStatic, $isAbstract, @parents);
    $className = "";
    $scope = "public";
    $isStatic = 0;
    $isAbstract = 0;
    @parents = ();
    my $classDefineDespEndIdx = index($machSub, "{");
    my $classDefineDesp = substr($machSub, 0, $classDefineDespEndIdx);

    if ($classDefineDesp =~ m/static\s/) {
		$isStatic = 1;
		$classDefineDesp =~ s/static\s+//;
    }
    if ($classDefineDesp =~ m/abstract\s/) {
		$isAbstract = 1;
		$classDefineDesp =~ s/abstract\s+//;
    }

	# private abstract static class ProfileQuery {
    if ($classDefineDesp =~ m/(\w+)\s+class\s+(\S+)/) {
	    if ("public" ne $1 && "protected" ne $1 && "private" ne $1) { $scope = "public"; }
    	else { $scope = $1; }
        $className = $2;
    }
    elsif ($classDefineDesp =~ m/class\s+(\S+)/) {
    	$scope = "public";
        $className = $1;
    }

	my $maybeExtendStartIdx = index($classDefineDesp, "extends");
	my $maybeImpStartIdx = index($classDefineDesp, "implements");

	my $hasExtend = 0;
	my $contExtend;
	my $hasImplement = 0;
	my $contImplement;

	if ($maybeExtendStartIdx < 0) {
		if ($maybeImpStartIdx > 0) {
			my $usefullStart = $maybeImpStartIdx + length("implements");
	        if ($classDefineDespEndIdx - $usefullStart > 0) {
	        	$hasImplement = 1;
	            $contImplement = substr($classDefineDesp, $usefullStart, ($classDefineDespEndIdx - $usefullStart));
	        }
		}
	}
	else {
		if ($maybeImpStartIdx < 0) {
	        my $usefullStart = $maybeExtendStartIdx + length("extends");
	        if ($classDefineDespEndIdx - $usefullStart > 0) {
	        	$hasExtend = 1;
	            $contExtend = substr($classDefineDesp, $usefullStart, ($classDefineDespEndIdx - $usefullStart));
				$contExtend = Util::stringTrim($contExtend);
	        }
		}
		else {
			# extends baseClass implements baseInterface0, baseInterface1 ...
			# java just only can be single inherted.
			if ($maybeImpStartIdx > $maybeExtendStartIdx) {
				my $extUsefullStart = $maybeExtendStartIdx + length("extends");
				$hasExtend = 1;
				$contExtend = substr($classDefineDesp, $extUsefullStart, $maybeImpStartIdx - $extUsefullStart);
				$contExtend = Util::stringTrim($contExtend);

				my $impUsefullStart = $maybeImpStartIdx + length("implements");
		        if ($classDefineDespEndIdx - $impUsefullStart > 0) {
		        	$hasImplement = 1;
		            $contImplement = substr($classDefineDesp, $impUsefullStart, ($classDefineDespEndIdx - $impUsefullStart));
		        }
			}
			else {
				print __LINE__.":[E]: implements idx < extends idx, check it.\n";
			}
		}
	}

	if (1 eq $hasExtend) {
		push (@parents, $contExtend);
	}

	if (1 eq $hasImplement) {
		my @parentsTemp = split(/,/, $contImplement);
		@parentsTemp = Util::stringTrimArray(@parentsTemp);
	    push (@parents, @parentsTemp);
	}

	# common
	$currNode->{ $FileTag::K_NodeType } = "CLASS";
	$currNode->{ $FileTag::K_NodeName } = $className;
	$currNode->{ $FileTag::K_SelfData } = "";

	# class
	$currNode->{ $FileTag::K_Scope } = $scope;
	$currNode->{ $FileTag::K_Abstract } = $isAbstract;
	$currNode->{ $FileTag::K_Static } = $isStatic;
	$currNode->{ $FileTag::K_Parents } = \@parents;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $classDefineDespEndIdx + 1, $classEndBracketsIdx - 1 - $classDefineDespEndIdx);
	$machSub = Util::stringTrim($machSub);
	if ("" ne $machSub) {
		&analysisContext($machSub, $currNode);
	}
}

sub analysisInterface
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my ($className, $scope, $isStatic, $isAbstract, @parents);
    $className = "";
    $scope = "public";
    $isStatic = 0;
    $isAbstract = 0;
    @parents = ();
    my $classDefineDespEndIdx = index($machSub, "{");
    my $classDefineDesp = substr($machSub, 0, $classDefineDespEndIdx);

	if ($classDefineDesp =~ m/static\s/) {
		$isStatic = 1;
		$classDefineDesp =~ s/static\s+//;
    }
    if ($classDefineDesp =~ m/abstract\s/) {
		$isAbstract = 1;
		$classDefineDesp =~ s/abstract\s+//;
    }

    if ($classDefineDesp =~ m/(\w+)\s+interface\s+(\S+)/) {
    	$scope = $1;
        $className = $2;
    }
    elsif ($classDefineDesp =~ m/interface\s+(\S+)/) {
    	$scope = "public";
        $className = $1;
    }

	my $maybeImpStartIdx = index($classDefineDesp, "implements");
	my $hasImplement = 0;
	my $contImplement;

	if ($maybeImpStartIdx > 0) {
		my $usefullStart = $maybeImpStartIdx + length("implements");
        if ($classDefineDespEndIdx - $usefullStart > 0) {
        	$hasImplement = 1;
            $contImplement = substr($classDefineDesp, $usefullStart, ($classDefineDespEndIdx - $usefullStart));
        }
	}

	if (1 eq $hasImplement) {
		my @parentsTemp = split(/,/, $contImplement);
		@parentsTemp = &StringTrimArray(@parentsTemp);
	    push (@parents, @parentsTemp);
	}

	# common
	$currNode->{ $FileTag::K_NodeType } = "INTERFACE";
	$currNode->{ $FileTag::K_NodeName } = $className;
	$currNode->{ $FileTag::K_SelfData } = "";

	# class
	$currNode->{ $FileTag::K_Scope } = $scope;
	$currNode->{ $FileTag::K_Abstract } = $isAbstract;
	$currNode->{ $FileTag::K_Static } = $isStatic;
	$currNode->{ $FileTag::K_Parents } = \@parents;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $classDefineDespEndIdx + 1, $classEndBracketsIdx - 1 - $classDefineDespEndIdx);
	$machSub = Util::stringTrim($machSub);
	if ("" ne $machSub) {
		&analysisContext($machSub, $currNode);
	}
}

sub analysisFuncDefine
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0);
	my $funcDefineDesp = substr($machSub, 0, $aimIdx + 1);
	my ($scope, $return, $isNative, $isStatic, $isFinal, $isAbstract, $isSynchronized, $funcName, @funcParams);
	$scope = "public";
	$return = "";
	$isNative = 0;
	$isStatic = 0;
	$isFinal = 0;
	$isAbstract = 0;
	$isSynchronized = 0;
	$funcName = "";
	@funcParams = ();
    if ($funcDefineDesp =~ m/(private|protected|public)\s+/) {
    	$scope = $1;
    	$funcDefineDesp =~ s/private|protected|public\s+//;
    }
	if ($funcDefineDesp =~ m/static\s+/) {
    	$isStatic = 1;
    	$funcDefineDesp =~ s/static\s+//;
    }
    if ($funcDefineDesp =~ m/native\s+/) {
    	$isNative = 1;
    	$funcDefineDesp =~ s/native\s+//;
    }
    if ($funcDefineDesp =~ m/abstract\s+/) {
    	$isAbstract = 1;
    	$funcDefineDesp =~ s/abstract\s+//;
    }
    if ($funcDefineDesp =~ m/synchronized\s+/) {
    	$isSynchronized = 1;
    	$funcDefineDesp =~ s/synchronized\s+//;
    }

    # must before '(' because parma may has final sign too.
    my $lsBrackIdx = index($funcDefineDesp, "(");
    if ($lsBrackIdx > 0) {
    	my $beforeBrackTmp = substr($funcDefineDesp, 0, $lsBrackIdx);
    	my $lastContTmp = substr($funcDefineDesp, $lsBrackIdx);
    	if ($beforeBrackTmp =~ m/final\s+/) {
	    	$isFinal = 1;
	    	$beforeBrackTmp =~ s/final\s+//;
	    	$funcDefineDesp = $beforeBrackTmp.$lastContTmp;
	    }
    }

    $funcDefineDesp = Util::stringTrim($funcDefineDesp);
    my $remainContext = Util::stringTrim(substr($funcDefineDesp, 0, index($funcDefineDesp, "(")));
    my $remainSubs = Util::splitComplexDataType($remainContext);
    #print __LINE__." after splitComplexDataType\n";
    #foreach (@$remainSubs) { print __LINE__." $_\n"; }
	if (2 eq @$remainSubs) {
		$return = $remainSubs->[0];
		$funcName = ucfirst($remainSubs->[1]);
	}
	elsif (1 eq @$remainSubs) {
		$funcName = ucfirst($remainSubs->[0]);
	}
	else {
    	print __LINE__.": donot obtain func name, failed. \$machSub=[$machSub]\n";
    }

	my $firstBracketIdx = index($funcDefineDesp, "(");
	my $lastBracketIdx = rindex($funcDefineDesp, ")");
	$funcDefineDesp = substr($funcDefineDesp, $firstBracketIdx + 1, ($lastBracketIdx - 1) - $firstBracketIdx);
    $funcDefineDesp = Util::stringTrim($funcDefineDesp);

	my $parmType;
    my $parmName;
   	my $paramsLine = Util::splitParamsDespLine($funcDefineDesp);
    foreach my $eachParm (@$paramsLine) {
    	$eachParm = Util::stringTrim($eachParm);
    	if ($eachParm =~ m/(\S+)$/) {
    		$parmName = $1;
    		my $parmNameStartIdx = rindex($eachParm, $parmName);
    		$parmType = substr($eachParm, 0, $parmNameStartIdx);

    		my %parmPair;
    		$parmPair{ $FileTag::K_ParamType } = Util::stringTrim($parmType);
    		$parmPair{ $FileTag::K_ParamName } = Util::stringTrim($parmName);
    		push (@funcParams, \%parmPair);
    	}
    }

    # will used in polish but not in java
    my @meybeHasInitList = ();
    my $colonIdx = index($machSub, ":", $aimIdx);
    if ($colonIdx >= 0) {
    	my $initListDesp = "";
    	my $leftBigBrackIdx = index($machSub, "{", $colonIdx);
    	if ($leftBigBrackIdx >= 0) {
			$initListDesp = substr($machSub, $colonIdx + 1, $leftBigBrackIdx - $colonIdx - 1);
    	}
    	else {
			$initListDesp = substr($machSub, $colonIdx + 1);
    	}
    	if ("" ne $initListDesp) {
			@meybeHasInitList = split(/,/, $initListDesp);
			@meybeHasInitList = Util::stringTrimArray(@meybeHasInitList);
    	}
    }

    # common
	$currNode->{ $FileTag::K_NodeType } = "FUNC";
	$currNode->{ $FileTag::K_NodeName } = $funcName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# func
	$currNode->{ $FileTag::K_Scope } = $scope;
	$currNode->{ $FileTag::K_Return } = $return;
	$currNode->{ $FileTag::K_Params } = \@funcParams;
	$currNode->{ $FileTag::K_Static } = $isStatic;
	$currNode->{ $FileTag::K_Final } = $isFinal;
	$currNode->{ $FileTag::K_Native } = $isNative;
	$currNode->{ $FileTag::K_Abstract } = $isAbstract;
	$currNode->{ $FileTag::K_Virtual } = 0;
	$currNode->{ $FileTag::K_PureVirtual } = 0;
	$currNode->{ $FileTag::K_Synchronized } = $isSynchronized;
	$currNode->{ $FileTag::K_InitList } = \@meybeHasInitList;
	$currNode->{ $FileTag::K_IsCarFunc } = 0;

	if ("INTERFACE" eq $currNode->currUpwardInClassOrInterface) {
		$currNode->{ $FileTag::K_Virtual } = 1;
		$currNode->{ $FileTag::K_PureVirtual } = 1;
	}
	elsif ("CLASS" eq $currNode->currUpwardInClassOrInterface) {
		if ("" eq $return) {
			$currNode->{ $FileTag::K_Virtual } = 0;
			$currNode->{ $FileTag::K_PureVirtual } = 0;
		}
		else {
			if ("private" ne $scope && 1 ne $isStatic) {
				my $lastNode = $currNode->lastBrother;
				if (exists ($lastNode->{ $FileTag::K_NodeTag }) && $lastNode->{ $FileTag::K_NodeTag } eq $FileTag::DC_astart) {
					my $selfData = $lastNode->{ $FileTag::K_SelfData };
 					if ($selfData =~ m/Override/) {
						$currNode->{ $FileTag::K_Virtual } = 0;
						$currNode->{ $FileTag::K_PureVirtual } = 0;
					}
					else {
						$currNode->{ $FileTag::K_Virtual } = 1;
						$currNode->{ $FileTag::K_PureVirtual } = 0;
					}
				}
				elsif (0 == $isStatic) {
					$currNode->{ $FileTag::K_Virtual } = 1;
					$currNode->{ $FileTag::K_PureVirtual } = 0;
				}

				if ("public" eq $scope && exists ($lastNode->{ $FileTag::K_NodeTag }) && $lastNode->{ $FileTag::K_NodeTag } ne $FileTag::DC_astart) {
					$currNode->{ $FileTag::K_IsCarFunc } = 1;
				}
			}
		}
	}

    #print __LINE__.": DealFunc: scope=$scope, ret=$return, isStatic=$isStatic, isFinal=$isFinal, funcName=$funcName, funcParam=[";
    #foreach my $parm (@funcParams) {
    #	print "$parm->{ $FileTag::K_ParamType }=>$parm->{ $FileTag::K_ParamName } ";
    #	if ($funcParams[$#funcParams] eq $parm) {
	#		print "]\n";
    #	}
    #}

    $firstBracketIdx = index($machSub, "{");
    ($isFind, $lastBracketIdx) = Util::findBracketsEnd($machSub, 2);
	if ($firstBracketIdx > 0 && 1 eq $isFind && $lastBracketIdx > 0) {
		$machSub = substr($machSub, $firstBracketIdx + 1, $lastBracketIdx - 1 - $firstBracketIdx);
		$machSub = Util::stringTrimFirstEndEmptyLine($machSub);
		$currNode->{ $FileTag::K_InnerContext } = $machSub;

		# first filter possible inner class
		if (1 eq $gAnalysisNoNameClass) {
			$machSub = &analysisFuncDefineInnerClass($tag, $machSub, $parNode, $currNode);
		}

		# analysis func inner content switch
		if (1 eq $gAnalysisFuncContent && "" ne $machSub) {
			#FileAnalysisJavaFuncContent::analysisFuncContent($machSub, $currNode);
		}
	}
}

# special, has return
# return: $result, that add note contexts
sub analysisFuncDefineInnerClass
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $result = $machSub;

	my $lastSub = "";
	my $overrideIdx = index($machSub, "\@Override");
	if ($overrideIdx >= 0) {
		my $bigBrackStartIdx = rindex($machSub, "{", $overrideIdx);
		if ($bigBrackStartIdx >= 0) {
			my ($isClassFind, $aimClassIdx) = Util::findBracketsEnd($machSub, 2, "->", $bigBrackStartIdx);
			if (1 eq $isClassFind) {
				my $classConstructSmallRightIdx = rindex($machSub, ")", $bigBrackStartIdx);
				my ($isClassConstustFind, $aimClassConstustIdx) = Util::findBracketsEnd($machSub, 0, "<-", $classConstructSmallRightIdx);
				if (1 eq $isClassConstustFind) {
					my $newStartIdx = rindex($machSub, "new ", $aimClassConstustIdx);
					my $classDesp = substr($machSub, $newStartIdx, $aimClassIdx - $newStartIdx + 1);
					# add note here
					if ($classDesp =~ m/new\s+(\S+)\(/) {
						my $tarClassName = Util::stringTrim($1);
						$tarClassName =~ s/\./::/g;
						my $currClassName = &buildInnerClassName($tarClassName);
						$result = Util::stringSplice($result, $newStartIdx, 0, "// [wuweizuo auto add note here: new $currClassName(this)] ");
					}

					my $currClassName;
					($classDesp, $currClassName) = &doCompleteClassDesp($tag, \$classDesp, $parNode, $currNode);
					my $upwardFirstClassNode = $currNode->getCurrNodeUpwardFirstClassOrInterface;
					&analysisContext($classDesp, $upwardFirstClassNode);
					$lastSub = substr($machSub, $aimClassIdx + 1);
				}
			}
		}

		if ("" ne $lastSub) {
			my $resultSub = &analysisFuncDefineInnerClass($tag, $lastSub, $parNode, $currNode);
			$result = Util::stringMoreStrSplice($result, $resultSub, $lastSub, "->", 0, 0, 0, length($lastSub));
		}
	}

	return $result;
}

sub analysisFuncCall
{
	print __LINE__." into nuFunc FuncCall, is it right?\n";
	<STDIN>;

	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0);
	my $funcDefineDesp = substr($machSub, 0, $aimIdx + 1);
	my ($scope, $srcHasScope, $return, $isNative, $isStatic, $isFinal, $funcName, @funcParams);
	$scope = "public";
	$srcHasScope = 0;
	$isNative = 0;
	$isStatic = 0;
	$isFinal = 0;

    if ($funcDefineDesp =~ m/(private|protected|public)\s+/) {
    	$scope = $1;
    	$srcHasScope = 1;
    	$funcDefineDesp =~ s/private|protected|public\s+//;
    }
	if ($funcDefineDesp =~ m/static\s+/) {
    	$isStatic = 1;
    	$funcDefineDesp =~ s/static\s+//;
    }
    if ($funcDefineDesp =~ m/final\s+/) {
    	$isFinal = 1;
    	$funcDefineDesp =~ s/final\s+//;
    }
    if ($funcDefineDesp =~ m/native\s+/) {
    	$isNative = 1;
    	$funcDefineDesp =~ s/native\s+//;
    }

    $funcDefineDesp = Util::stringTrim($funcDefineDesp);
    if ($funcDefineDesp =~ m/(\S+)\s+(\S+)\s*\(/) {
    	$return = $1;
    	$funcName = $2;
    	$funcName = ucfirst($funcName);
    }
    elsif ($funcDefineDesp =~ m/^(\S+)\s*\(/) {
    	$funcName = $1;
    	$funcName = ucfirst($funcName);
    }
    else {
    	print __LINE__.": donot obtain func name, failed.\n";
    }

	my $firstBracketIdx = index($funcDefineDesp, "(");
	my $lastBracketIdx = rindex($funcDefineDesp, ")");
	$funcDefineDesp = substr($funcDefineDesp, $firstBracketIdx + 1, ($lastBracketIdx - 1) - $firstBracketIdx);
    $funcDefineDesp = Util::stringTrim($funcDefineDesp);

	my $parmType;
    my $parmName;
    my @parms = split(/,/, $funcDefineDesp);
    foreach my $eachParm (@parms) {
    	$eachParm = Util::stringTrim($eachParm);
    	if ($eachParm =~ m/(\S+)$/) {
    		$parmName = $1;
    		my $parmNameStartIdx = rindex($eachParm, $parmName);
    		$parmType = substr($eachParm, 0, $parmNameStartIdx);

    		my %parmPair;
    		$parmPair{ $FileTag::K_ParamType } = $parmType;
    		$parmPair{ $FileTag::K_ParamName } = $parmName;
    		push (@funcParams, \%parmPair);
    	}
    }

    # common
	$currNode->{ $FileTag::K_NodeType } = "FUNC";
	$currNode->{ $FileTag::K_NodeName } = $funcName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# func
	$currNode->{ $FileTag::K_Scope } = $scope;
	$currNode->{ $FileTag::K_SrcHasScope } = $srcHasScope;

    #print __LINE__.": DealFunc: scope=$scope, ret=$return, isStatic=$isStatic, isFinal=$isFinal, funcName=$funcName, funcParam=[";
    foreach my $parm (@funcParams) {
    	#print "$parm->{ $FileTag::K_ParamType } => $parm->{ $FileTag::K_ParamName }\n";
    }
    #print "]\n";

    $firstBracketIdx = index($machSub, "{");
	$lastBracketIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $firstBracketIdx + 1, $lastBracketIdx - 1 - $firstBracketIdx);
	$machSub = Util::stringTrim($machSub);
	if ("" ne $machSub) {
		&analysisContext($machSub, $currNode);
	}
}

sub analysisVarDefine
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $scope = "public";
	my $isStatic = 0;
	my $isFinal = 0;
	my $varComplexType = "";

	if ($machSubTmp =~ m/(private|protected|public)\s+/) {
    	$scope = $1;
    	$machSubTmp =~ s/private|protected|public\s+//;
    }
	if ($machSubTmp =~ m/static\s+/) {
    	$isStatic = 1;
    	$machSubTmp =~ s/static\s+//;
    }
    if ($machSubTmp =~ m/final\s+/) {
    	$isFinal = 1;
    	$machSubTmp =~ s/final\s+//;
    }

    $machSubTmp = Util::stringTrim($machSubTmp);
	# likes or more:
	# private boolean isOk;
	# protected SparseArray<IntentCallback> mOutstandingIntents;
	# protected HashMap<Integer, String> mIntentErrors;
	# protected const HashMap<Integer, String> mIntentErrors;
	# protected const String[] mIntentErrors;
	my $semicoIdx = rindex($machSubTmp, ";");
	my @maybeMoreVars = ();
	if ($semicoIdx >= 0) {
		my $commaIdx = index($machSubTmp, ",");
		# has ',', may has more than one var define
		# such as: "int a, b;"
		if ($commaIdx > 0) {
			if ($machSubTmp =~ m/(\S+\s*,)/) {
				my $firstNameStartIdx = index($machSubTmp, $1);
				if ($firstNameStartIdx < 0) { print __LINE__." error\n"; <STDIN>; }
				my $varDefinesContent = substr($machSubTmp, $firstNameStartIdx, $semicoIdx - $firstNameStartIdx);
				@maybeMoreVars = split(/,/, $varDefinesContent);
				@maybeMoreVars = Util::stringTrimArray(@maybeMoreVars);
				$varComplexType = substr($machSubTmp, 0, $firstNameStartIdx);
				$varComplexType = Util::stringTrim($varComplexType);
			}
		}
		else {
			if ($machSubTmp =~ m/(\S+)\s*;$/) {
				my $variableName = $1;
				push @maybeMoreVars, $variableName;
				my $nameIdx = rindex($machSubTmp, $variableName);
				$varComplexType = substr($machSubTmp, 0, $nameIdx);
				$varComplexType = Util::stringTrim($varComplexType);
			}
		}
	}
	else {
		print __LINE__.": [E]: format error\n";
	}

	my $firstVarName = $maybeMoreVars[0];
    # common
	$currNode->{ $FileTag::K_NodeType } = "VAR_DEFINE";
	$currNode->{ $FileTag::K_NodeName } = $firstVarName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	$currNode->{ $FileTag::K_Scope } = $scope;
	$currNode->{ $FileTag::K_Static } = $isStatic;
	$currNode->{ $FileTag::K_Final } = $isFinal;

	# var
	$currNode->{ $FileTag::K_VarType } = $varComplexType;
	$currNode->{ $FileTag::K_VarName } = $firstVarName;

	for (my $idx=1; $idx<@maybeMoreVars; ++$idx) {
		my $newNode = new FileAnalysisStruct;
		$newNode->{ $FileTag::K_NodeTag } = $tag;
		$newNode->{ $FileTag::K_ParNode } = $parNode;
		$parNode->appendChildNode( $newNode );
		# common
		$newNode->{ $FileTag::K_NodeType } = "VAR_DEFINE";
		$newNode->{ $FileTag::K_NodeName } = $maybeMoreVars[$idx];
		$newNode->{ $FileTag::K_SelfData } = $machSub;

		$newNode->{ $FileTag::K_Scope } = $scope;
		$newNode->{ $FileTag::K_Static } = $isStatic;
		$newNode->{ $FileTag::K_Final } = $isFinal;

		# var
		$newNode->{ $FileTag::K_VarType } = $varComplexType;
		$newNode->{ $FileTag::K_VarName } = $maybeMoreVars[$idx];
	}
}

sub analysisVarAssignment
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $scope = "public";
	my $varComplexType;
	my $variableName;
	my $variableValue;
	my $variableTargetValue;

	if ($machSubTmp =~ m/(private|protected|public)\s+/) {
		$scope = $1;
	}
	$machSubTmp =~ s/private|protected|public\s+//;

	my $equalIdx = index($machSubTmp, "=");
	my $beforeEqualTmp = substr($machSubTmp, 0, $equalIdx);

	# likes or more:
	# private boolean[] isOk = new { **** };
	# protected SparseArray<IntentCallback> mOutstandingIntents = 15;
	# protected HashMap<Integer, String> mIntentErrors = new Hash<String>();
	# protected const HashMap<Integer, String> mIntentErrors = mOwner.getService().getResource().screen;
	# protected const String[] mIntentErrors = new String[] {
	#    13, 23, 43
	# };
	# before then "=" is varible define and after it is varible target value, this value maybe is a sample data or
	# a complex data from class or function call, even maybe has a override function that need create a
	# new child class and so on.
	my $afterEqualTmp = substr($machSubTmp, $equalIdx + 1);

	# common
	$currNode->{ $FileTag::K_NodeType } = "VAR_ASSIGNMENT";
	# var
	$currNode->{ $FileTag::K_Scope } = $scope;

	my $assignLeft = new FileAnalysisStruct;
	my $assignRight = new FileAnalysisStruct;
	$currNode->{ $FileTag::K_VarAssL } = $assignLeft; # specify child node
	$currNode->{ $FileTag::K_VarAssR } = $assignRight;
	$assignLeft->{ $FileTag::K_ParNode } = $currNode;
	$assignRight->{ $FileTag::K_ParNode } = $currNode;
	&analysisVarAssignmentLeft($tag, $beforeEqualTmp, $currNode, $assignLeft);
	&analysisVarAssignmentRight($tag, $afterEqualTmp, $currNode, $assignLeft, $assignRight);
}

sub analysisVarAssignmentLeft
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $scope = "public";
	my $isStatic = 0;
	my $isFinal = 0;
	my $varComplexType;
	my $variableName;

	if ($machSubTmp =~ m/(private|protected|public)\s+/) {
    	$scope = $1;
    	$machSubTmp =~ s/private|protected|public\s+//;
    }
	if ($machSubTmp =~ m/static\s+/) {
    	$isStatic = 1;
    	$machSubTmp =~ s/static\s+//;
    }
    if ($machSubTmp =~ m/final\s+/) {
    	$isFinal = 1;
    	$machSubTmp =~ s/final\s+//;
    }

    $machSubTmp = Util::stringTrim($machSubTmp);
	# likes or more:
	# private boolean isOk;
	# protected SparseArray<IntentCallback> mOutstandingIntents;
	# protected HashMap<Integer, String> mIntentErrors;
	# protected const HashMap<Integer, String> mIntentErrors;
	# protected const String[] mIntentErrors;
	if ($machSubTmp =~ m/(\S+)\s*$/) {
		$variableName = $1;
		my $nameIdx = rindex($machSubTmp, $variableName);
		$varComplexType = substr($machSubTmp, 0, $nameIdx);
		$varComplexType = Util::stringTrim($varComplexType);
	}

    # common
    $currNode->{ $FileTag::K_NodeTag } = $tag;
	$currNode->{ $FileTag::K_NodeType } = "VAR_ASSIGNMENT_LEFT";
	$currNode->{ $FileTag::K_NodeName } = $variableName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	$currNode->{ $FileTag::K_Scope } = $scope;
	$currNode->{ $FileTag::K_Static } = $isStatic;
	$currNode->{ $FileTag::K_Final } = $isFinal;

	# var
	$currNode->{ $FileTag::K_VarType } = $varComplexType;
	$currNode->{ $FileTag::K_VarName } = $variableName;
}

sub analysisVarAssignmentRight
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $assignLeft = shift;
	my $currNode = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $leftType = $assignLeft->{ $FileTag::K_VarType };
	my $varComplexType = "";
	my $variableName = "";

	$currNode->{ $FileTag::K_VarAsiRType } = -1;
	$machSubTmp =~ s/\s*;$//g;
    # common
    $currNode->{ $FileTag::K_NodeTag } = $tag;
	$currNode->{ $FileTag::K_NodeType } = "VAR_ASSIGNMENT_RIGHT";
	$currNode->{ $FileTag::K_SelfData } = $machSubTmp;

	if (1 eq TransElastosType::isCommonType(TransElastosType::obtUsefullType($leftType))) {
		return;
	}

	# inner func that should new create a sub class of main class
	# @Override can be think as a specify func sign of java
	# in this situation new will always appear

	# is a single value;
	if ($machSubTmp =~ m/^(\S+)$/) {
		my $mach = $1;
		if ($mach eq "null") {
			if ($leftType eq "String") { $mach = "String(\"\")"; }
			elsif ($leftType =~ m/^Int\d+$/) { $mach = "0"; }
			elsif ($leftType =~ m/^Float$/) { $mach = "0"; }
			else { $mach = "NULL"; }
		}
		# has '.', may be a var.var, check first
		elsif ($mach =~ m/^(\S+?)\./) {
			my $firstWord = $1;
			if (1 eq Util::isStrFirstUpper($firstWord)) {
				my $dstCarType = "";
				if (1 eq TransElastosType::isCarType($firstWord, \$dstCarType)) {
					$mach =~ s/\./::/;
					$mach = "I".$mach;
				}
				else {
					$mach =~ s/\./::/;
				}
			}
			else {
				print __LINE__." analysisVarAssignmentR: into var. first is lowwer, has this situation?\n";
				<STDIN>;
			}
		}
		$currNode->{ $FileTag::K_SelfData } = $mach;
	}

	# start with new
	# this may be is a override class, array init, object new
	elsif ($machSubTmp =~ m/^new\s+/) {
		my $machSubTmp1 = $machSubTmp;
		$machSubTmp1 =~ s/^new\s+//;
		# new array
		if ($machSubTmp1 =~ m/^(\S+?)\s*\[/) {
			my $newWhat = $1;
			$machSubTmp1 =~ s/^(\S+?)\s*//;
			my $firstMidBrackInnerCont = "";
			if ($machSubTmp1 =~ m/^\[(.*?)\]/) {
				$firstMidBrackInnerCont = $1;
				$machSubTmp1 =~ s/^\[(.*?)\]\s*//;
			}
			my $hasSecondMid = 0;
			my $secondMidBrackInnerCont = "";
			if ($machSubTmp1 =~ m/^\[(.*?)\]/) {
				$hasSecondMid = 1;
				$secondMidBrackInnerCont = $1;
				$machSubTmp1 =~ s/^\[(.*?)\]\s*//;
			}
			# after [] is '{', it is a array and has init.
			# it will newly added a function to do init
			if ($machSubTmp1 =~ m/^\{/) {
				print __LINE__." mach array and has init============\n";
				&doCompARArrHasInitFuncDesp($tag, \$machSubTmp, $parNode, $assignLeft, $currNode);
			}
			# it just is a array but has no init
			else {
				print __LINE__." mach array and has no init============\n";
				&doCompARArrNoInitFuncDesp($tag, \$machSubTmp, $parNode, $assignLeft, $currNode);
			}
		}

		# new a class
		elsif ($machSubTmp1 =~ m/^(\S)+?\s*\(/) {
			my $newWhat = $1;
			$machSubTmp1 =~ s/^(\S)+?\s*//;
			my $lBrackIdx = index($machSubTmp1, "(");
			my ($rBrackFind, $rBrackIdx) = Util::findBracketsEnd($machSubTmp1, 0, "->", 0);
			my $paramContent = Util::stringTrim(substr($machSubTmp1, $lBrackIdx + 1, $rBrackIdx - $lBrackIdx - 1));
			$machSubTmp1 = Util::stringTrim(substr($machSubTmp1, $rBrackIdx + 1));
			# after () is '{', it may be has a override func
			# it will newly added a function to do init
			if ($machSubTmp1 =~ m/^\{/) {
				print __LINE__." mach class and has { that may has inner override class============\n";
				my ($classDesp, $currClassName) = &doCompleteClassDesp($tag, \$machSubTmp, $parNode, $currNode);
				my $newCreate = "new $currClassName(this)";
				$currNode->{ $FileTag::K_SelfData } = $newCreate;
				my $mainClassNode = $currNode->getMainClassOrInterface;
				&analysisContext($classDesp, $mainClassNode);
			}
			# it just is a new Object and no other init
			else {
				print __LINE__." mach array and has init============\n";
				# nothing to do here, selfData has set in at begin.
			}
		}
		else {
			print __LINE__." assign right new into else============\n";
			<STDIN>;
		}
	}

	# start with '{' directly, it will be a common array init
	elsif ($machSubTmp =~ m/^{/) {
		print __LINE__." mach array and direct init============\n";
		&doCompARArrDirectInitFuncDesp($tag, \$machSubTmp, $parNode, $assignLeft, $currNode);
	}

	# is a func call
	elsif ($machSubTmp =~ m/^(\S+?)\.(\S+?)\s*\(/ || $machSubTmp =~ m/^(\S+?)\s*\(/) {
		print __LINE__." mach func call============\n";
		&doCompARFuncCallFuncDesp($tag, \$machSubTmp, $parNode, $assignLeft, $currNode);
	}

	elsif ($machSubTmp =~ m/{/ && $machSubTmp =~ m/\(/ && $machSubTmp =~ m/\@Override/) {
		print __LINE__." into elaif\n";
		<STDIN>;
		my $lastSub = "";
		my $overrideIdx = index($machSubTmp, "\@Override");
		if ($overrideIdx >= 0) {
			my $bigBrackStartIdx = rindex($machSubTmp, "{", $overrideIdx);
			if ($bigBrackStartIdx >= 0) {
				my ($isClassFind, $aimClassIdx) = Util::findBracketsEnd($machSubTmp, 2, "->", $bigBrackStartIdx);
				if (1 eq $isClassFind) {
					my $classConstructSmallRightIdx = rindex($machSubTmp, ")", $bigBrackStartIdx);
					my ($isClassConstustFind, $aimClassConstustIdx) = Util::findBracketsEnd($machSubTmp, 0, "<-", $classConstructSmallRightIdx);
					if (1 eq $isClassConstustFind) {
						my $newStartIdx = rindex($machSubTmp, "new ", $aimClassConstustIdx);
						my $classDesp = substr($machSubTmp, $newStartIdx, $aimClassIdx - $newStartIdx + 1);
						# add note here
						if ($classDesp =~ m/new\s+(\S+)\(/) {
							my $tarClassName = Util::stringTrim($1);
							$tarClassName =~ s/\./::/g;
							my $currClassName = &buildInnerClassName($tarClassName);

						}

						my $currClassName;
						($classDesp, $currClassName) = &doCompleteClassDesp($tag, \$classDesp, $parNode, $currNode);
						#print __LINE__." after doCompleteClassDesp: \$classDesp=\n[\n$classDesp\n]\n";
						my $mainClassNode = $currNode->getMainClassOrInterface;
						&analysisContext($classDesp, $mainClassNode);
						my $lastSub0 = substr($machSubTmp, 0, $newStartIdx);
						my $lastSub1 = substr($machSubTmp, $aimClassIdx + 1);
						my $newCreate = "new $currClassName(this)";

						$lastSub = $lastSub0.$newCreate.$lastSub1;
					}
				}
			}

			if ("" ne $lastSub) {
				my $resultSub = &analysisFuncDefineInnerClass($tag, $lastSub, $parNode, $currNode);
			}
		}

		$currNode->{ $FileTag::K_VarAsiRType } = 1;
		$currNode->{ $FileTag::K_VarAsiRHasNew } = 1;
	}

	else {
		print __LINE__." [analysisVarAssignmentRight]: analysis var assign right no match, check it\n";
		print __LINE__." [analysisVarAssignmentRight]: \$machSub=\n[$machSub]\n";
		<STDIN>;
	}
}

sub analysisCurrTag
{
    my $input = shift;
    my $parNode = shift;
    $input = Util::stringTrim($input);
    #print __LINE__." into analysisCurrTag: \$input=$input\n";

    my $inputHasWrap = $input;
    my $inputNoWrap = $input;
    $inputNoWrap =~ s/\r|\n/\t/g;

    my ($stayContent, $tag, $machSub);
    $stayContent = "";
    $tag = -1;
    $machSub = "";
    my $checkOk = 0;
    my $checkMachIdx = 0;

	# content can end with follow types.
	# 1: empty(specify invalid content)
	# 2: note(specify invalid content)
	# 3: begin with @(specify invalid content)
	# 4: end with semicolon
	# 5: end with big brackets

	# 1: check is empty
	if (0 eq $checkOk) {
		if ("" eq $inputHasWrap) {
			$machSub = "";
	    	$stayContent = Util::stringTrim($inputHasWrap);
			$tag = $FileTag::DC_empty;
	    	$checkOk = 1;
	    	$checkMachIdx = 1;
		}
	}

	# 2: check note specify invalid content
	# is note? note is invalid content
	if (0 eq $checkOk) {
		if ($inputNoWrap =~ m/^(\/\*.*?\*\/)/g) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	$tag = $FileTag::DC_note;
	    	$checkOk = 1;
	    	$checkMachIdx = 2;
	    }
	    # elsif ($inputHasWrap =~ m/^(\/\/.*)$/) {
	    elsif ($inputHasWrap =~ m/^(\/\/.*)/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	$tag = $FileTag::DC_note;
	    	$checkOk = 1;
	    	$checkMachIdx = 2;
	    }
	}

	# 3: check begin with @(specify invalid content)
	#  and  check specify format that start with "package" or "import"
	if (0 eq $checkOk) {
		if ($inputHasWrap =~ m/^(@.*?)\n/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	$tag = $FileTag::DC_astart;
	    	$checkOk = 1;
	    	$checkMachIdx = 3;
	    }
	    elsif ($inputHasWrap =~ m/^(package\s+.*?)\n/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	$tag = $FileTag::DC_package;
	    	$checkOk = 1;
	    	$checkMachIdx = 3;
	    }
	    elsif ($inputHasWrap =~ m/^(import\s+.*?)\n/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	$tag = $FileTag::DC_import;
	    	$checkOk = 1;
	    	$checkMachIdx = 3;
	    }
	}

	#print __LINE__." \$firstSemicIdx=$firstSemicIdx, \$firstBracketIdx=$firstBracketIdx\n";
	#if (-1 eq $firstSemicIdx && -1 eq $firstBracketIdx) {
	#	print __LINE__." \$inputHasWrap=$inputHasWrap\n";
	#}
	# 4: check end with ";" or "};" or ");"
	if (0 == $checkOk) {
		my ($endSymbol, $endSymIdx) = Util::obtEndSymbol($inputHasWrap);
		#print __LINE__." analysisCurrTag: \$endSymbol=$endSymbol, \$endSymIdx=$endSymIdx\n";

		if (";" eq $endSymbol) {
			$machSub = substr($inputHasWrap, 0, $endSymIdx+1);
			$stayContent = substr($inputHasWrap, $endSymIdx+1);

			#print __LINE__." \$isEndWithSemic=$isEndWithSemic, \$usefullEndSemicIdx=$usefullEndSemicIdx \$machSub=[$machSub]\n";

			#print __LINE__." into 4\n";
			my $firstSemicIdx = index($inputHasWrap, ";");
			my $firstSmallBracketIdx = index($inputHasWrap, "(");
			my $firstBigBracketIdx = index($inputHasWrap, "{");
			my $subNoWrapTmp = substr($inputNoWrap, 0, $endSymIdx+1);
			my $subHasWrapTmp = substr($inputHasWrap, 0, $endSymIdx+1);

			my @firstIdxs;
			push @firstIdxs, $firstSemicIdx;
			push @firstIdxs, $firstSmallBracketIdx;
			push @firstIdxs, $firstBigBracketIdx;
			#print __LINE__." \@firstIdxs=@firstIdxs\n";
			#print __LINE__." \$firstSemicIdx=$firstSemicIdx, \$firstSmallBracketIdx=$firstSmallBracketIdx, \$firstBigBracketIdx=$firstBigBracketIdx\n";

			my $usefullMinIdx = Util::usefullMin(\@firstIdxs, -1);
			my $equalIdx = index($subNoWrapTmp, "=");

			#print __LINE__." \$equalIdx=$equalIdx, \$usefullMinIdx=$usefullMinIdx\n";

			# varible assignment
			if ($equalIdx >= 0 && $equalIdx < $usefullMinIdx) {
				$tag = $FileTag::DC_var_assignment;
		    	$checkOk = 1;
		    	$checkMachIdx = 4;
			}
			# may be varible or function
			else {
				# may be a func
				if ($subNoWrapTmp =~ m/\(/) {
					if ($parNode->isCurrUpwardInType("FUNC")) {
						# find ".", it is func call
						if ($subNoWrapTmp =~ m/\./) {
							$tag = $FileTag::DC_function_call;
			    			$checkOk = 1;
			    			$checkMachIdx = 4;
						}
					}
					else {
						$tag = $FileTag::DC_function_define;
		    			$checkOk = 1;
		    			$checkMachIdx = 4;
					}
				}
				else {
					$tag = $FileTag::DC_var_define;
		    		$checkOk = 1;
		    		$checkMachIdx = 4;
				}
			}
		}

		# 5: end with "}"
		if (0 eq $checkOk && "}" eq $endSymbol) {
			# find the end
			my ($isFind, $aimIdx) = Util::findBracketsEnd($inputHasWrap, 2);
			#print __LINE__." findBracketsEnd: \$isFind=$isFind, \$aimIdx=$aimIdx\n";

			if (1 eq $isFind) {
				$machSub = substr($inputHasWrap, 0, $aimIdx+1);
				$stayContent = substr($inputHasWrap, $aimIdx+1);
			}
			else {
				print __LINE__."[E] find brackets end failed.\n";
			}

			my $firstSemicIdx = index($inputHasWrap, ";");
			my $firstSmallBracketIdx = index($inputHasWrap, "(");
			my $firstBigBracketIdx = index($inputHasWrap, "{");
			my $leftBracketsSub = substr($inputHasWrap, 0, $firstBigBracketIdx);
			if ($leftBracketsSub =~ m/class\s+/) {
				$tag = $FileTag::DC_class;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/interface\s+/) {
				$tag = $FileTag::DC_interface;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/else\s+if\s+/) {
				$tag = $FileTag::DC_logic_elseif;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/else\s+/) {
				$tag = $FileTag::DC_logic_else;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/if\s+/) {
				$tag = $FileTag::DC_logic_if;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/switch\s+/) {
				$tag = $FileTag::DC_logic_switch;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/while\s+/) {
				$tag = $FileTag::DC_logic_while;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/for\s+/) {
				$tag = $FileTag::DC_logic_for;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/\S+\s+\S+\s*?\(/ && $leftBracketsSub =~ m/\)/) {
				$tag = $FileTag::DC_function_define;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/\S+\s*?\(/ && $leftBracketsSub =~ m/\)/) {
				$tag = $FileTag::DC_function_define;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			else {
				$tag = $FileTag::DC_logic_unknow;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
		}
	}

	#print __LINE__." CheckMachIdx=$checkMachIdx\n";

	# all else
	if (0 eq $checkOk) {
		$tag = $FileTag::DC_unknown;
		print __LINE__."[E] CheckCurrTag no match, failed. \$input=[$input]\n";
	}

	#print __LINE__."[N] CheckCurrTag: \$stayContent=[$stayContent], \$tag=[$tag], \$machSub=[$machSub]\n";
    return ($stayContent, $tag, $machSub);
}

sub doCompleteClassDesp
{
	my $tag = shift;
	my $machSubPtr = shift;
	my $parNode = shift;
	my $currNode = shift;

	my $machSub = $$machSubPtr;
	my $tarClassName = "";
	my $currClassName = "";
	$machSub =~ s/^\s*?new\s+//g;
	if ($machSub =~ m/^(.*?)\(/) {
		$tarClassName = $1;
		$currClassName = &buildInnerClassName($tarClassName);
		my $tarClassNameTmp = quotemeta $tarClassName;
		$machSub =~ s/^$tarClassNameTmp\s*//g;

		# such as: InnerCallable<String[]>
		# bacause car has no template
		if ($currClassName =~ m/^(\w+|\d+)/) {
			$currClassName = $1;
		}
	}
	my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0, "->", 0);
	my $constrFuncParm = substr($machSub, 1, $aimIdx - 1);
	$$machSubPtr = "new $currClassName($constrFuncParm)";

	my $classSub = Util::stringTrim(substr($machSub, $aimIdx + 1));
	my $classDesp = "private class $currClassName extends $tarClassName\n";
	my $upwardFirstClassNode = $currNode->getCurrNodeUpwardFirstClassOrInterface;
	my $upwardFirstClassName = "";
	if (defined($upwardFirstClassNode)) { $upwardFirstClassName = $upwardFirstClassNode->{ $FileTag::K_NodeName }; }

	my $suppleConstructFunc = "\npublic $currClassName($upwardFirstClassName* owner)\n : mOwner(owner)\n {\n";
	$suppleConstructFunc = $suppleConstructFunc."    mOwner = owner;\n";
	$suppleConstructFunc = $suppleConstructFunc."}\n";
	my $suppleUpwardVar = "\nprivate $upwardFirstClassName* mOwner;\n";

	my $reg0 = qr /\S+/;
	my $reg1 = qr /{/;
	my $reg2 = qr /}/;
	$machSub = Util::stringTrim($machSub);
	$machSub = Util::stringSplice($machSub, 0, index($machSub, "{"), $classDesp);
	$machSub = Util::stringMoreStrSplice($machSub, $suppleConstructFunc, "{", "->", 0, 1, 0, 0);
	$machSub = Util::stringSplice($machSub, rindex($machSub, "}"), 0, $suppleUpwardVar);
	return ($machSub, $currClassName);
}

sub doCompARArrNoInitFuncDesp
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $assignLeft = shift;
	my $currNode = shift;

	$$machSub =~ s/^\s*new\s+//;
	my $firstBrackIdx = index($$machSub, "{");
	my ($isFind, $endIdx) = Util::findBracketsEnd($$machSub, 2);
	my $tarName = Util::stringTrim(substr($$machSub, 0, $firstBrackIdx));

	my $leftType = $assignLeft->{ $FileTag::K_VarType };
	my $innerContent = "$leftType result = new $$machSub;\n";

	my $assignLeftScope = $assignLeft->{ $FileTag::K_Scope };
	my $assignLeftStatic = $assignLeft->{ $FileTag::K_Static };
	my $assignLeftFinal = $assignLeft->{ $FileTag::K_Final };
	my $assignLeftVarType = $assignLeft->{ $FileTag::K_VarType };
	my $assignLeftVarName = $assignLeft->{ $FileTag::K_VarName };

	print __LINE__." \$assignLeftVarType=$assignLeftVarType\n";

	my $funcNameTmp = $assignLeftVarName;
	my @funcNameTmps = split(/_/, $funcNameTmp);
	my $namesTmps = Util::toLowerArray(\@funcNameTmps);
	$namesTmps = Util::ucfirstArray($namesTmps);
	$funcNameTmp = join "", @$namesTmps;
	$funcNameTmp = "MiddleInit".$funcNameTmp;

	my $assiRightFuncNode = new FileAnalysisStruct; {
		$assiRightFuncNode->{ $FileTag::K_NodeTag } = $FileTag::DC_function_define;
		$assiRightFuncNode->{ $FileTag::K_Scope } = "private";

		$assiRightFuncNode->{ $FileTag::K_NodeType } = "FUNC";
		$assiRightFuncNode->{ $FileTag::K_Return } = $assignLeftVarType;
		$assiRightFuncNode->{ $FileTag::K_NodeName } = $funcNameTmp;
		$assiRightFuncNode->{ $FileTag::K_Static } = $assignLeftStatic;
		$assignLeft->{ $FileTag::K_Final } = 0;	# change left node type, make it no const
		$assiRightFuncNode->{ $FileTag::K_Final } = 0;
		$assiRightFuncNode->{ $FileTag::K_Native } = 0;
		$assiRightFuncNode->{ $FileTag::K_Abstract } = 0;
		$assiRightFuncNode->{ $FileTag::K_Virtual } = 0;
		$assiRightFuncNode->{ $FileTag::K_PureVirtual } = 0;
		my @emptyParmas = ();
		my @emptyFuncInitList = ();
		$assiRightFuncNode->{ $FileTag::K_Params } = \@emptyParmas;
		$assiRightFuncNode->{ $FileTag::K_InitList } = @emptyFuncInitList;
		$assiRightFuncNode->{ $FileTag::K_ParNode } = $parNode;

		my $funcContentBuf = "";
		if (1 eq $assignLeftStatic) { $funcContentBuf = $funcContentBuf."static "; }
		$funcContentBuf = $funcContentBuf.$assignLeftVarType." $funcNameTmp() {\n" ;
		$funcContentBuf = $funcContentBuf.$innerContent."\n}\n";
		$assiRightFuncNode->{ $FileTag::K_SelfData } = $funcContentBuf;
		$assiRightFuncNode->{ $FileTag::K_InnerContext } = $innerContent;

		my $parClassNode = $parNode->getSpecifyTypeNodeUpwardRecursive("CLASS");
		$parClassNode->appendChildNode($assiRightFuncNode);

		if (1 eq $assignLeftStatic) {
			my $parClassPath = $parClassNode->currScopePath;
			$currNode->{ $FileTag::K_SelfData } = "$parClassPath::$funcNameTmp()";
		}
	}
}

sub doCompARArrHasInitFuncDesp
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $assignLeft = shift;
	my $currNode = shift;

	$$machSub =~ s/^\s*new\s+//;
	my $firstBrackIdx = index($$machSub, "{");
	my ($isFind, $endIdx) = Util::findBracketsEnd($$machSub, 2);
	my $tarName = Util::stringTrim(substr($$machSub, 0, $firstBrackIdx));
	my $leftType = $assignLeft->{ $FileTag::K_VarType };
	my $innerContent = Util::stringTrim(substr($$machSub, $firstBrackIdx+1, $endIdx-$firstBrackIdx-1));
	$innerContent = "->WWZ_SIGN: ARRAY_INIT_START {\n".$innerContent."\n";
	$innerContent = $innerContent."->WWZ_SIGN: ARRAY_INIT_END }\n";

	my $assignLeftScope = $assignLeft->{ $FileTag::K_Scope };
	my $assignLeftStatic = $assignLeft->{ $FileTag::K_Static };
	my $assignLeftFinal = $assignLeft->{ $FileTag::K_Final };
	my $assignLeftVarType = $assignLeft->{ $FileTag::K_VarType };
	my $assignLeftVarName = $assignLeft->{ $FileTag::K_VarName };

	print __LINE__." \$assignLeftVarType=$assignLeftVarType\n";

	my $funcNameTmp = $assignLeftVarName;
	my @funcNameTmps = split(/_/, $funcNameTmp);
	my $namesTmps = Util::toLowerArray(\@funcNameTmps);
	$namesTmps = Util::ucfirstArray($namesTmps);
	$funcNameTmp = join "", @$namesTmps;
	$funcNameTmp = "MiddleInit".$funcNameTmp;

	my $assiRightFuncNode = new FileAnalysisStruct; {
		$assiRightFuncNode->{ $FileTag::K_NodeTag } = $FileTag::DC_function_define;
		$assiRightFuncNode->{ $FileTag::K_Scope } = "private";

		$assiRightFuncNode->{ $FileTag::K_NodeType } = "FUNC";
		$assiRightFuncNode->{ $FileTag::K_Return } = $assignLeftVarType;
		$assiRightFuncNode->{ $FileTag::K_NodeName } = $funcNameTmp;
		$assiRightFuncNode->{ $FileTag::K_Static } = $assignLeftStatic;
		$assignLeft->{ $FileTag::K_Final } = 0;	# change left node type, make it no const
		$assiRightFuncNode->{ $FileTag::K_Final } = 0;
		$assiRightFuncNode->{ $FileTag::K_Native } = 0;
		$assiRightFuncNode->{ $FileTag::K_Abstract } = 0;
		$assiRightFuncNode->{ $FileTag::K_Virtual } = 0;
		$assiRightFuncNode->{ $FileTag::K_PureVirtual } = 0;
		my @emptyParmas = ();
		my @emptyFuncInitList = ();
		$assiRightFuncNode->{ $FileTag::K_Params } = \@emptyParmas;
		$assiRightFuncNode->{ $FileTag::K_InitList } = @emptyFuncInitList;
		$assiRightFuncNode->{ $FileTag::K_ParNode } = $parNode;

		my $funcContentBuf = "";
		if (1 eq $assignLeftStatic) { $funcContentBuf = $funcContentBuf."static "; }
		$funcContentBuf = $funcContentBuf.$assignLeftVarType." $funcNameTmp() {\n" ;
		$funcContentBuf = $funcContentBuf.$innerContent."\n}\n";
		$assiRightFuncNode->{ $FileTag::K_SelfData } = $funcContentBuf;
		$assiRightFuncNode->{ $FileTag::K_InnerContext } = $innerContent;

		my $parClassNode = $parNode->getSpecifyTypeNodeUpwardRecursive("CLASS");
		$parClassNode->appendChildNode($assiRightFuncNode);

		if (1 eq $assignLeftStatic) {
			my $parClassPath = $parClassNode->currScopePath;
			$currNode->{ $FileTag::K_SelfData } = "$parClassPath::$funcNameTmp()";
		}
	}
}

sub doCompARArrDirectInitFuncDesp
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $assignLeft = shift;
	my $currNode = shift;

	$$machSub =~ s/^\s*new\s+//;
	my $firstBrackIdx = index($$machSub, "{");
	my ($isFind, $endIdx) = Util::findBracketsEnd($$machSub, 2);
	my $tarName = Util::stringTrim(substr($$machSub, 0, $firstBrackIdx));
	my $innerContent = Util::stringTrim(substr($$machSub, $firstBrackIdx+1, $endIdx-$firstBrackIdx-1));
	$innerContent = "->WWZ_SIGN: ARRAY_INIT_START {\n".$innerContent."\n";
	$innerContent = $innerContent."->WWZ_SIGN: ARRAY_INIT_END }\n";

	my $assignLeftScope = $assignLeft->{ $FileTag::K_Scope };
	my $assignLeftStatic = $assignLeft->{ $FileTag::K_Static };
	my $assignLeftFinal = $assignLeft->{ $FileTag::K_Final };
	my $assignLeftVarType = $assignLeft->{ $FileTag::K_VarType };
	my $assignLeftVarName = $assignLeft->{ $FileTag::K_VarName };

	print __LINE__." \$assignLeftVarType=$assignLeftVarType\n";

	my $funcNameTmp = $assignLeftVarName;
	my @funcNameTmps = split(/_/, $funcNameTmp);
	my $namesTmps = Util::toLowerArray(\@funcNameTmps);
	$namesTmps = Util::ucfirstArray($namesTmps);
	$funcNameTmp = join "", @$namesTmps;
	$funcNameTmp = "MiddleInit".$funcNameTmp;

	my $assiRightFuncNode = new FileAnalysisStruct; {
		$assiRightFuncNode->{ $FileTag::K_NodeTag } = $FileTag::DC_function_define;
		$assiRightFuncNode->{ $FileTag::K_Scope } = "private";

		$assiRightFuncNode->{ $FileTag::K_NodeType } = "FUNC";
		$assiRightFuncNode->{ $FileTag::K_Return } = $assignLeftVarType;
		$assiRightFuncNode->{ $FileTag::K_NodeName } = $funcNameTmp;
		$assiRightFuncNode->{ $FileTag::K_Static } = $assignLeftStatic;
		$assignLeft->{ $FileTag::K_Final } = 0;	# change left node type, make it no const
		$assiRightFuncNode->{ $FileTag::K_Final } = 0;
		$assiRightFuncNode->{ $FileTag::K_Native } = 0;
		$assiRightFuncNode->{ $FileTag::K_Abstract } = 0;
		$assiRightFuncNode->{ $FileTag::K_Virtual } = 0;
		$assiRightFuncNode->{ $FileTag::K_PureVirtual } = 0;
		my @emptyParmas = ();
		my @emptyFuncInitList = ();
		$assiRightFuncNode->{ $FileTag::K_Params } = \@emptyParmas;
		$assiRightFuncNode->{ $FileTag::K_InitList } = @emptyFuncInitList;
		$assiRightFuncNode->{ $FileTag::K_ParNode } = $parNode;

		my $funcContentBuf = "";
		if (1 eq $assignLeftStatic) { $funcContentBuf = $funcContentBuf."static "; }
		$funcContentBuf = $funcContentBuf.$assignLeftVarType." $funcNameTmp() {\n" ;
		$funcContentBuf = $funcContentBuf.$innerContent."\n}\n";
		$assiRightFuncNode->{ $FileTag::K_SelfData } = $funcContentBuf;
		$assiRightFuncNode->{ $FileTag::K_InnerContext } = $innerContent;

		my $parClassNode = $parNode->getSpecifyTypeNodeUpwardRecursive("CLASS");
		$parClassNode->appendChildNode($assiRightFuncNode);

		if (1 eq $assignLeftStatic) {
			my $parClassPath = $parClassNode->currScopePath;
			$currNode->{ $FileTag::K_SelfData } = "$parClassPath::$funcNameTmp()";
		}
	}
}

# start with: "XXX.XXX(" or "XXX("
# $machSubTmp =~ m/^(\S+?)\.(\S+?)\s*\(/ || $machSubTmp =~ m/^(\S+?)\s*\(/
sub doCompARFuncCallFuncDesp
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $assignLeft = shift;
	my $currNode = shift;

	my $leftStatic = $assignLeft->{ $FileTag::K_Static };
	my $leftUsefullStatic = $leftStatic;
	if (0 eq $leftStatic) {
		my $parClassNode = $parNode->getSpecifyTypeNodeUpwardRecursive("CLASS");
		$leftUsefullStatic = $parClassNode->{ $FileTag::K_Static };
	}

	my $hasCaller = 0;
	my $caller = "";
	if ($$machSub =~ m/^(\S+?)\.(\S+?)\s*\(/) {
		$hasCaller = 1;
		$caller = $1;
		$$machSub =~ s/^(\S+?)\.//;
	}

	if (1 eq $leftUsefullStatic) {
		my $firstBrackIdx = index($$machSub, "(");
		my ($isFind, $endIdx) = Util::findBracketsEnd($$machSub, 0);
		my $funcName = Util::stringTrim(substr($$machSub, 0, $firstBrackIdx));
		my $paramsContent = Util::stringTrim(substr($$machSub, $firstBrackIdx+1, $endIdx-$firstBrackIdx-1));
		$paramsContent = "->WWZ_SIGN: FUNC_CALL_START {\n".$paramsContent."\n";
		$paramsContent = $paramsContent."->WWZ_SIGN: FUNC_CALL_END }\n";

		my $assignLeftScope = $assignLeft->{ $FileTag::K_Scope };
		my $assignLeftStatic = 1;
		my $assignLeftFinal = $assignLeft->{ $FileTag::K_Final };
		my $assignLeftVarType = $assignLeft->{ $FileTag::K_VarType };
		my $assignLeftVarName = $assignLeft->{ $FileTag::K_VarName };

		my $funcNameTmp = $assignLeftVarName;
		my @funcNameTmps = split(/_/, $funcNameTmp);
		my $namesTmps = Util::toLowerArray(\@funcNameTmps);
		$namesTmps = Util::ucfirstArray($namesTmps);
		$funcNameTmp = join "", @$namesTmps;
		$funcNameTmp = "MiddleInit".$funcNameTmp;

		my $assiRightFuncNode = new FileAnalysisStruct; {
			$assiRightFuncNode->{ $FileTag::K_NodeTag } = $FileTag::DC_function_define;
			$assiRightFuncNode->{ $FileTag::K_Scope } = "private";

			$assiRightFuncNode->{ $FileTag::K_NodeType } = "FUNC";
			$assiRightFuncNode->{ $FileTag::K_Return } = $assignLeftVarType;
			$assiRightFuncNode->{ $FileTag::K_NodeName } = $funcNameTmp;
			$assiRightFuncNode->{ $FileTag::K_Static } = $assignLeftStatic;
			$assignLeft->{ $FileTag::K_Final } = 0;	# change left node type, make it no const
			$assignLeft->{ $FileTag::K_Static } = 1; # change left node type, make it is static
			$assiRightFuncNode->{ $FileTag::K_Final } = 0;
			$assiRightFuncNode->{ $FileTag::K_Native } = 0;
			$assiRightFuncNode->{ $FileTag::K_Abstract } = 0;
			$assiRightFuncNode->{ $FileTag::K_Virtual } = 0;
			$assiRightFuncNode->{ $FileTag::K_PureVirtual } = 0;
			my @emptyParmas = ();
			my @emptyFuncInitList = ();
			$assiRightFuncNode->{ $FileTag::K_Params } = \@emptyParmas;
			$assiRightFuncNode->{ $FileTag::K_InitList } = \@emptyFuncInitList;
			$assiRightFuncNode->{ $FileTag::K_ParNode } = $parNode;

			my $funcContentBuf = "";
			if (1 eq $assignLeftStatic) { $funcContentBuf = $funcContentBuf."static "; }
			$funcContentBuf = $funcContentBuf.$assignLeftVarType." $funcNameTmp() {\n" ;
			$funcContentBuf = $funcContentBuf.$paramsContent."\n}\n";
			$assiRightFuncNode->{ $FileTag::K_SelfData } = $funcContentBuf;
			$assiRightFuncNode->{ $FileTag::K_InnerContext } = $paramsContent;

			my $parClassNode = $parNode->getSpecifyTypeNodeUpwardRecursive("CLASS");
			$parClassNode->appendChildNode($assiRightFuncNode);

			if (1 eq $assignLeftStatic) {
				my $parClassPath = $parClassNode->currScopePath;
				$currNode->{ $FileTag::K_SelfData } = "$parClassPath::$funcNameTmp()";
			}
		}
	}
	else {
		print __LINE__." doCompARFuncCallFuncDesp: isnot static, is it do nothing?\n";
	}
}

my %g_classNameHash = ();
sub buildInnerClassName
{
	my $newClassName = shift;
	$newClassName =~ s/\.//;
	$newClassName =~ s/:://;
	$newClassName = "Inner".$newClassName;

	my $classIdx = 0;
	if (exists ($g_classNameHash{ $newClassName })) {
		$classIdx = $g_classNameHash{ $newClassName };
		$g_classNameHash{ $newClassName } = ++$classIdx;
	}
	else {
		$g_classNameHash{ $newClassName } = 0;
	}

	if (0 ne $classIdx) {
		$newClassName = $newClassName.$classIdx;
	}
	return $newClassName;
}

sub getImportStrBySpecifyEnd
{
	my $node = shift;
	my $specifyEnd = shift;
	my @packages = ();
	my @imports = ();
	ToolDealImports::analysisNodeImports($node, \@packages, \@imports);
	#$node->testOutputStruct;
	my $import = "";
	my $lastSub = "";
	#print __LINE__." into getImportStrBySpecifyEnd, \$specifyEnd=$specifyEnd\n";
	foreach my $data (@imports) {
		$import = $data;
		$import =~ s/^import\s+//;
		$import =~ s/\s*;\s*$//;
		$lastSub = Util::getSplitSubStr($import, qr/\./, -1);
		#print __LINE__." \$import=$import, \$lastSub=$lastSub\n";
		if ($specifyEnd eq $lastSub) {
			return $data;
		}
	}
	return "";
}



1;
