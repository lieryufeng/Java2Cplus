#!/usr/bin/perl;

package FileAnalysisCar;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( analysisCar_Files  analysisCar_File );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;
use ElastosConfig;
use FileAnalysisCarPolish;


my $gValidCarName = "";
my $gCarDoc;
my $gPolishedInterfaceNodes;
sub obtFuzzyCarName
{
	my $currCarName = shift;
	my $currCarNameTmp = $currCarName;
	my ($analysisOk, $realCarName);
	$analysisOk = 0;
	$realCarName = "";

	my ($machOk, $doc) = &analysisCar_SpecifyCarNameFile($currCarNameTmp);
	if (1 eq $machOk) {
		$gCarDoc = $doc;
		$gValidCarName = $currCarNameTmp;
		$gPolishedInterfaceNodes = FileAnalysisCarPolish::polishCar_AnalisisStruct($doc);
		$analysisOk = 1;
		$realCarName = $currCarNameTmp;
		return ($analysisOk, $realCarName);
	}
	else {
		if ($currCarNameTmp =~ m/^I/) { $currCarNameTmp =~ s/^I//; }
		else { $currCarNameTmp = "I".$currCarNameTmp; }
		($machOk, $doc) = &analysisCar_SpecifyCarNameFile($currCarNameTmp);
		if (1 eq $machOk) {
			$gCarDoc = $doc;
			$gValidCarName = $currCarNameTmp;
			$gPolishedInterfaceNodes = FileAnalysisCarPolish::polishCar_AnalisisStruct($doc);
			$analysisOk = 1;
			$realCarName = $currCarNameTmp;
			return ($analysisOk, $realCarName);
		}
		else {
			$analysisOk = 0;
			$realCarName = "";
			print __LINE__." obtFuzzyCarName $currCarName failed\n";
			<STDIN>;
		}
	}
}

sub obtSpecifyFuncInCurrCar
{
	my $currFuncName = shift;
	my $parmCnt = shift;

	my ($find, $funcNode);
	$find = 0;

	my $currCarName = $gValidCarName;
	$currFuncName = ucfirst($currFuncName);

	my $findCarType = 0;
	my $findFunc = 0;

	my $carPath = $gCarDoc->{ $FileTag::K_NodeName };
	my $carName = Util::getFileNameByPath($carPath);

	#print __LINE__." \$carName=[$carName], \$currCarName=[$currCarName]\n";

	if ($carName eq $currCarName) {
		#print __LINE__." into carName equal\n";

		$findCarType = 1;
		my $currInterfaceName = $currCarName;
		if ($currInterfaceName !~ m/^I/) { $currInterfaceName = "I".$currInterfaceName; }
		if ($currInterfaceName =~ m/\.\w+$/) { $currInterfaceName =~ s/\.\w+//; }

		my $interfaceCnt = @$gPolishedInterfaceNodes;
		#print __LINE__." \$interfaceCnt=$interfaceCnt\n";

		foreach my $interface (@$gPolishedInterfaceNodes) {
			my $interfaceName = $interface->{ $FileTag::K_NodeName };
			#print __LINE__." \$interfaceName=$interfaceName, \$currInterfaceName=$currInterfaceName\n";

			if ($currInterfaceName eq $interfaceName) {
				my $subs = $interface->{ $FileTag::K_SubNodes };
				my $subsCnt = @$subs;
				#print __LINE__." \$subsCnt=$subsCnt\n";

				foreach my $child (@$subs) {
					my $nodeType = $child->{ $FileTag::K_NodeType };
					my $nodeName = $child->{ $FileTag::K_NodeName };
					#print __LINE__." [$nodeType] [$nodeName]\n";

					if ("FUNC" eq $child->{ $FileTag::K_NodeType }) {
						my $carFuncName = $child->{ $FileTag::K_NodeName };
						#print __LINE__." $currFuncName, $carFuncName\n";
						if ($currFuncName eq $carFuncName) {
							#print __LINE__." func [$carFuncName] found\n";

							my $params = $child->{ $FileTag::K_Params };
							my $paramsCnt = @$params;
							# simple check the count of param whether equal
							# car func will more the one that last one is output param
							if ($parmCnt eq $paramsCnt - 1) {
								$findFunc = 1;
								$find = 1;
								$funcNode = $child;
								return ($find, $funcNode);
							}
						}
					}
				}
			}
		}
	}

	if ($findCarType eq 0) {
		print __LINE__." obtSpecifyFuncInCurrCar cannot find car $currCarName\n";
		if ($findFunc eq 0) {
			print __LINE__." obtSpecifyFuncInCurrCar can not find func $currFuncName\n";
		}
		#<STDIN>;
	}

	return ($find, $funcNode);
}

sub clearObt
{
	$gValidCarName = "";
	undef $gCarDoc;
}

sub analysisCar_AllCar
{
	my $base = ElastosConfig::getElastosBaseDir;
	my $allCarPaths = FileOperate::readDir($base, ".car");
	my $docs;

	# test
	my $test = 1;
	if (1 eq $test) {
		my @tmps = ();
		push @tmps, "/home/lieryufeng/self/program/Self_Project/JavaToCplus_by_pm/IMatcher.car";
		my $path = $allCarPaths->[0];
		print __LINE__." \$path=$path\n";

		$docs = &analysisCar_Files(\@tmps);
	}
	else {
		$docs = &analysisCar_Files($allCarPaths);
	}

	return $docs;
}

sub analysisCar_Files
{
	my $currCarPaths = shift;
	my @docs = ();
    foreach my $path (@$currCarPaths) {
        push @docs, &analysisCar_File($path);
        print __LINE__." analycar: $path\n";
    }
    return \@docs;
}

sub analysisCar_SpecifyCarNameFile
{
	my $currCarName = shift;
	my $base = ElastosConfig::getElastosBaseDir;
	my $allCarPaths = FileOperate::readDir($base, ".car");
	my $machPath = "";
	my ($machOk, $doc);
	$machOk = 0;
	foreach my $path (@$allCarPaths) {
		my $name = FileOperate::getFileNameByPath($path);
		if ($name eq $currCarName) {
			$machOk = 1;
			$machPath = $path;
			last;
		}
	}

	if (0 eq $machOk) {
		print __LINE__." analysisCar_SpecifyCarNameFile has no mach\n";
		return ($machOk, $doc);
	}
	$doc = &analysisCar_File($machPath);
	return ($machOk, $doc);
}

# test
my $gCurrCarPath = "";
sub analysisCar_File
{
	my $currCarPath = shift;
   	my $carDataLines = FileOperate::readFile($currCarPath);
   	my $carDataContext = join " ", @$carDataLines;
   	$carDataContext = &removeInvalidContext($carDataContext);
	# test
   	$gCurrCarPath = $currCarPath;
    my $doc = createRootNode FileAnalysisStruct($currCarPath);
   	&analysisCar_Context($carDataContext, $doc);
   	return $doc;
}

sub removeInvalidContext
{
	my $carDataContext = shift;
	$carDataContext =~ s/\r|\n/\t/g;
	$carDataContext =~ s/\/\*.*?\*\///g;
	$carDataContext =~ s/\t/\n/g;
	$carDataContext =~ s/\/\/.*?\n/\n/g;
	return $carDataContext;
}

sub analysisCar_Context
{
   	my $remainDataContext = shift;
   	my $parNode = shift;

    while (1) {
    	my ($remainDataTmp, $tag, $machSub) = &analysisCar_CurrTag($remainDataContext, $parNode);
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
	    		&analysisCar_Empty($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_note eq $tag) {
	    		&analysisCar_Note($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_midbrackets_note eq $tag) {
	    		&analysisCar_MidbracketsNote($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_function_define eq $tag) {
	    		&analysisCar_FuncDefine($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_interface_quote eq $tag) {
	    		&analysisCar_InterfaceQuote($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_namespace eq $tag) {
	    		&analysisCar_Namespace($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_using_namespace eq $tag) {
	    		&analysisCar_UsingNamespace($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_interface eq $tag) {
	    		&analysisCar_Interface($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_module eq $tag) {
	    		&analysisCar_Module($tag, $machSub, $parNode, $newNode);
	    	}
	    	elsif ($FileTag::DC_typedef eq $tag) {
	    		&analysisCar_Typedef($tag, $machSub, $parNode, $newNode);
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

sub analysisCar_Empty
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "EMPTY";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = "\n";
}

sub analysisCar_Note
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "NOTE";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;
}

sub analysisCar_MidbracketsNote
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	$currNode->{ $FileTag::K_NodeType } = "MID_BRACKETS";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;
}

sub analysisCar_FuncDefine
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0);
	my $funcDefineDesp = substr($machSub, 0, $aimIdx + 1);
	my ($funcName, @funcParams);
	$funcName = "";
	@funcParams = ();

    $funcDefineDesp = Util::stringTrim($funcDefineDesp);
    $funcName = Util::stringTrim(substr($funcDefineDesp, 0, index($funcDefineDesp, "(")));

	my $firstBracketIdx = index($funcDefineDesp, "(");
	my $lastBracketIdx = rindex($funcDefineDesp, ")");
	$funcDefineDesp = substr($funcDefineDesp, $firstBracketIdx + 1, ($lastBracketIdx - 1) - $firstBracketIdx);
    $funcDefineDesp = Util::stringTrim($funcDefineDesp);

	my $parmType;
    my $parmName;
   	my @parmTmps = split(/,/, $funcDefineDesp);
    foreach my $eachParm (@parmTmps) {
    	$eachParm = Util::stringTrim($eachParm);
    	if ($eachParm =~ m/(\w+)$/) {
    		$parmName = $1;
			my $inOutType = "";
    		my $parmNameStartIdx = rindex($eachParm, $parmName);
    		$eachParm = substr($eachParm, 0, $parmNameStartIdx);
    		if ($eachParm =~ m/^\[\s*in\s*\]\s+/) {
    			$inOutType = "IN";
    			$eachParm =~ s/^\[\s*in\s*\]\s+//;
    		}
    		elsif ($eachParm =~ m/^\[\s*out\s*\]\s+/) {
				$inOutType = "OUT";
				$eachParm =~ s/^\[\s*out\s*\]\s+//;
    		}

			my %parmPair;
			$parmPair{ $FileTag::K_ParamInOutType } = $inOutType;
    		$parmPair{ $FileTag::K_ParamName } = Util::stringTrim($parmName);
    		$parmPair{ $FileTag::K_ParamType } = Util::stringTrim($eachParm);
    		push (@funcParams, \%parmPair);
    	}
    }

    # common
	$currNode->{ $FileTag::K_NodeType } = "FUNC";
	$currNode->{ $FileTag::K_NodeName } = $funcName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# func
	$currNode->{ $FileTag::K_Scope } = "public";
	$currNode->{ $FileTag::K_Return } = "";
	$currNode->{ $FileTag::K_Params } = \@funcParams;
	$currNode->{ $FileTag::K_Static } = 0;
	$currNode->{ $FileTag::K_Final } = 0;
	$currNode->{ $FileTag::K_Native } = 0;
	$currNode->{ $FileTag::K_Virtual } = 1;
	$currNode->{ $FileTag::K_PureVirtual } = 1;
}

sub analysisCar_InterfaceQuote
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my $interfaceName;

    if ($machSub =~ m/^interface\s+(\S+)\s*;/) {
    	$interfaceName = $1;
    }

	# common
	$currNode->{ $FileTag::K_NodeType } = "INTERFACE_QUOTE";
	$currNode->{ $FileTag::K_NodeName } = $interfaceName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# class
	$currNode->{ $FileTag::K_Scope } = "public";
}

sub analysisCar_Namespace
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my $namespaceName;

    if ($machSub =~ m/^namespace\s+(\S+)\s*{/) {
    	$namespaceName = $1;
    }

	# common
	$currNode->{ $FileTag::K_NodeType } = "NAMESPACE";
	$currNode->{ $FileTag::K_NodeName } = $namespaceName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	my $firstBrackIdx = index($machSub, "{");
	my $endBrackIdx = rindex($machSub, "}");
	my $remainContent = substr($machSub, $firstBrackIdx+1, $endBrackIdx-$firstBrackIdx-1);
	$remainContent = Util::stringTrim($remainContent);
	if ("" ne $remainContent) {
		&analysisCar_Context($remainContent, $currNode);
	}
}

sub analysisCar_UsingNamespace
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my $namespaceName;

    if ($machSub =~ m/^using\s+namespace\s+(\S+?)\s*;/) {
    	$namespaceName = $1;
    }

	# common
	$currNode->{ $FileTag::K_NodeType } = "USING_NAMESPACE";
	$currNode->{ $FileTag::K_NodeName } = $namespaceName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# class
	$currNode->{ $FileTag::K_Scope } = "public";
}

sub analysisCar_Interface
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my ($interfaceName, @parents);
    $interfaceName = "";
    @parents = ();
    my $classDefineDespEndIdx = index($machSub, "{");
    my $classDefineDesp = substr($machSub, 0, $classDefineDespEndIdx);
	if ($classDefineDesp =~ m/^interface\s+(\S+)/) {
        $interfaceName = $1;
    }

	my $maybeExtendStartIdx = index($classDefineDesp, "extends");
	my $hasExtend = 0;
	my $contExtend;
    my $usefullStart = $maybeExtendStartIdx + length("extends");
    if ($classDefineDespEndIdx - $usefullStart > 0) {
    	$hasExtend = 1;
        $contExtend = substr($classDefineDesp, $usefullStart, ($classDefineDespEndIdx - $usefullStart));
		$contExtend = Util::stringTrim($contExtend);
    }

    if (1 eq $hasExtend) {
		push (@parents, $contExtend);
	}

	# common
	$currNode->{ $FileTag::K_NodeType } = "INTERFACE";
	$currNode->{ $FileTag::K_NodeName } = $interfaceName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# class
	$currNode->{ $FileTag::K_Scope } = "public";
	$currNode->{ $FileTag::K_Parents } = \@parents;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $classDefineDespEndIdx + 1, $classEndBracketsIdx - 1 - $classDefineDespEndIdx);
	$machSub = Util::stringTrim($machSub);
	if ("" ne $machSub) {
		&analysisCar_Context($machSub, $currNode);
	}
}

sub analysisCar_Module
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	$currNode->{ $FileTag::K_NodeType } = "MODULE";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;

    my $classDefineDespEndIdx = index($machSub, "{");
    my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $classDefineDespEndIdx + 1, $classEndBracketsIdx - 1 - $classDefineDespEndIdx);
	&analysisCar_Context($machSub, $currNode);
}

sub analysisCar_Typedef
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	$currNode->{ $FileTag::K_NodeType } = "TYPEDEF";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $machSub;
    # nothing to do here.
}

sub analysisCar_CurrTag
{
    my $input = shift;
    my $parNode = shift;
    $input = Util::stringTrim($input);
    #print __LINE__." into analysisCar_CurrTag: \$input=$input\n";

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
		if ($inputHasWrap =~ m/^(\[.*?\])\n/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	$tag = $FileTag::DC_midbrackets_note;
	    	$checkOk = 1;
	    	$checkMachIdx = 3;
	    }
	}

	#print __LINE__." \$firstSemicIdx=$firstSemicIdx, \$firstBracketIdx=$firstBracketIdx\n";
	#if (-1 eq $firstSemicIdx && -1 eq $firstBracketIdx) {
	#	print __LINE__." \$inputHasWrap=$inputHasWrap\n";
	#}
	# 4: check end with ";" or "};" or ");"
	# maybe interface single line quote or function define.
	if (0 eq $checkOk) {
		my ($endSymbol, $endSymIdx) = Util::obtEndSymbol($inputHasWrap);
		#my $testLast = substr($inputHasWrap, $endSymIdx);
		#print __LINE__." analysisCar_CurrTag: \$endSymbol=$endSymbol, \$endSymIdx=$endSymIdx, \$testLast=$testLast\n";

		if (";" eq $endSymbol) {
			$machSub = substr($inputHasWrap, 0, $endSymIdx+1);
			$stayContent = substr($inputHasWrap, $endSymIdx+1);

			if ($machSub =~ m/\w+\s*\(/) {
				$tag = $FileTag::DC_function_define;
		    	$checkOk = 1;
		    	$checkMachIdx = 4;
			}
			elsif ($machSub =~ m/^interface\s+.+?;$/) {
				$tag = $FileTag::DC_interface_quote;
		    	$checkOk = 1;
		    	$checkMachIdx = 4;
			}
			elsif ($machSub =~ m/^typedef\s+.+?;$/) {
				$tag = $FileTag::DC_typedef;
		    	$checkOk = 1;
		    	$checkMachIdx = 4;
			}
			elsif ($machSub =~ m/^using\s+interface\s+.+?;$/) {
				$tag = $FileTag::DC_using_namespace;
		    	$checkOk = 1;
		    	$checkMachIdx = 4;
			}
			else {
			}
		}

		# 5: end with "}"
		if (0 eq $checkOk && "}" eq $endSymbol) {
			# find the end
			my ($isFind, $aimIdx) = Util::findBracketsEnd($inputHasWrap, 2);
			if (1 eq $isFind) {
				$machSub = substr($inputHasWrap, 0, $aimIdx+1);
				$stayContent = substr($inputHasWrap, $aimIdx+1);
			}
			else {
				#print __LINE__."[E] find brackets end failed.\n";
			}

			if ($machSub =~ m/^namespace\s+\S+\s*{/) {
				$tag = $FileTag::DC_namespace;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($machSub =~ m/^interface\s+\S+\s*.*?{/) {
				$tag = $FileTag::DC_interface;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($machSub =~ m/^module/) {
				$tag = $FileTag::DC_module;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($machSub =~ m/^library/) {
				$tag = $FileTag::DC_module;
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
		#my @tmps = split(/\n/, $input);
		#my $firstLine = $tmps[0];
		#if (1 eq @tmps) {
		#	$firstLine = substr($tmps[0], 0, 100);
		#}
		#print __LINE__."[E] CheckCurrTag no match, failed. \$input=[$firstLine...]\n";
	}

	#print __LINE__."[N] CheckCurrTag: \$stayContent=[$stayContent], \$tag=[$tag], \$machSub=[$machSub]\n";
    return ($stayContent, $tag, $machSub);
}


1;

