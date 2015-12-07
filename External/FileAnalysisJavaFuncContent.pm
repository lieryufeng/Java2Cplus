#!/usr/bin/perl;

package FileAnalysisJavaFuncContent;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use warnings;
use TransElastosType;
use FileAnalysisCar;
use ScopeStackManager;

my @gFixedVaribles = ();

sub analysisFuncContent
{
	my $javaFuncContext = shift;
	my $funcNode = shift;
	ScopeStackManager::globalObtVaribles($funcNode);
	ScopeStackManager::stackBeginNewScope;

	my @funcContentTransed = ();
	my $startSpace = "";
	&analysisContext($javaFuncContext, $funcNode, $startSpace, \@funcContentTransed);

	my $funcContext = Util::stringArrayFormatLine(\@funcContentTransed, $startSpace);
   	my $funcContextLine = join "\n", @$funcContext;
   	$funcContextLine = $funcContextLine."\n"; # append end \n
	$funcNode->{ $FileTag::K_InnerContextTransed } = $funcContextLine;

	ScopeStackManager::globalReset;
	ScopeStackManager::stackReset;
	#print __LINE__." \$funcContextLine=\n$funcContextLine\n";
}

sub analysisContext
{
   	my $remainDataContext = shift;
   	my $parNode = shift;
   	my $startSpace = shift;
   	my $funcContentsTransed = shift;

    while (1) {
		last if ("" eq $remainDataContext);
		#print __LINE__." \$remainDataContext=$remainDataContext\n";
    	my ($remainDataTmp, $tag, $machSub) = &analysisCurrWholeTag($remainDataContext, $parNode);
    	$remainDataContext = $remainDataTmp;;
    	#print __LINE__." \$remainDataContext=[$remainDataContext]\n";
		my $strTag = FileTag::getTagString($tag);
		#print "--mach [$strTag] [$machSub]\n";
		#sleep 1;
		if (FileTag::isTagValid($tag)) {
			my $newNode = new FileAnalysisStruct;
			$newNode->{ $FileTag::K_NodeTag } = $tag;
			$newNode->{ $FileTag::K_ParNode } = $parNode;
			$parNode->appendChildNode( $newNode );

			if ($FileTag::DC_return eq $tag) {
	    		&analysisWhole_Return($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
			elsif ($FileTag::DC_empty eq $tag) {
	    		&analysisWhole_Empty($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_astart eq $tag) {
	    		&analysisWhole_AStart($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_note eq $tag) {
	    		&analysisWhole_Note($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
			elsif ($FileTag::DC_function_call eq $tag) {
	    		&analysisWhole_FuncCall($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_if eq $tag) {
	    		&analysisWhole_LogicIf($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_elseif eq $tag) {
	    		&analysisWhole_LogicElseIf($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_else eq $tag) {
	    		&analysisWhole_LogicElse($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_switch eq $tag) {
	    		&analysisWhole_LogicSwitch($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_while eq $tag) {
	    		&analysisWhole_LogicWhile($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_for eq $tag) {
	    		&analysisWhole_LogicFor($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_try eq $tag) {
	    		&analysisWhole_LogicTry($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_catch eq $tag) {
	    		&analysisWhole_LogicCatch($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_logic_finally eq $tag) {
	    		&analysisWhole_LogicFinally($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_var_define eq $tag) {
	    		&analysisWhole_VarDefine($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	elsif ($FileTag::DC_var_assignment eq $tag) {
	    		&analysisWhole_VarAssignment($tag, $machSub, $parNode, $newNode, $startSpace, $funcContentsTransed);
	    	}
	    	else {
	    		print __LINE__."[E] \$DC var match failed.\n";
	    	}
		}
		else {
		}

    	if ("" eq $remainDataContext) {
    		print __LINE__." into last\n";
    		last;
    	}
    }
}

sub analysisWhole_Return
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	$currNode->{ $FileTag::K_NodeType } = "RETURN";
	$currNode->{ $FileTag::K_SelfData } = &fmtSelfData($machSub, $startSpace);

	# second output dst content
	$machSub =~ s/^\s*return\s+//;
	my @tmpsRes = ();
	my $last = &analysisContext($machSub, $parNode, \@tmpsRes, "");
	if (@tmpsRes > 1) {
		push @tmpsRes, $startSpace."return result;\n";
		my $funcContext = Util::stringArrayFormatLine(\@tmpsRes, $startSpace);
		my $selfDataTransed = join "", @tmpsRes;
		$currNode->{ $FileTag::K_SelfDataTransed } = $selfDataTransed;
		push @$funcContentsTransed, @tmpsRes;
	}
	elsif (@tmpsRes eq 1) {
		my $tmp = $tmpsRes[0];
		$tmp = Util::stringTrim($tmp);
		$tmp = $startSpace."return $tmp;\n";
		$currNode->{ $FileTag::K_SelfDataTransed } = $tmp;
		push @$funcContentsTransed, $tmp;
	}
	else {
		print __LINE__." return empty? check it\n";
		#<STDIN>;
		#die;
	}
}

sub analysisWhole_Empty
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	$currNode->{ $FileTag::K_NodeType } = "EMPTY";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = "\n";
	$currNode->{ $FileTag::K_SelfDataTransed } = "\n";
	push @$funcContentsTransed, "\n";
}

sub analysisWhole_AStart
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	$currNode->{ $FileTag::K_NodeType } = "\@START";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = &fmtSelfData($machSub, $startSpace);
	$currNode->{ $FileTag::K_SelfDataTransed } = "";

	# do not need AStart
}

sub analysisWhole_Note
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	$currNode->{ $FileTag::K_NodeType } = "NOTE";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = &fmtSelfData($machSub, $startSpace);
	my $selfTransedData = &fmtSelfTransedData($machSub, $startSpace);
	$currNode->{ $FileTag::K_SelfDataTransed } = $selfTransedData;
	push @$funcContentsTransed, $selfTransedData;
}

sub analysisWhole_FuncCall
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	# common
	$currNode->{ $FileTag::K_NodeType } = "FUNC_CALL";
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# is special "super(***);"
	my @funcCallContentTransed = ();
	&doAnalysisWhole_FuncCall($machSub, $parNode, $startSpace, \@funcCallContentTransed);
	push @$funcContentsTransed, @funcCallContentTransed;
}

sub analysisWhole_LogicIf
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

    my $logicDespEndIdx = index($machSub, "{");
    my $logicDefineDesp = substr($machSub, 0, $logicDespEndIdx);

	# common
	$currNode->{ $FileTag::K_NodeType } = "IF";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $logicDefineDesp;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $logicDespEndIdx + 1, $classEndBracketsIdx - 1 - $logicDespEndIdx);
	return &analysisContext($machSub, $currNode);
}

sub analysisWhole_LogicElseIf
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

    my $logicDespEndIdx = index($machSub, "{");
    my $logicDefineDesp = substr($machSub, 0, $logicDespEndIdx);

	# common
	$currNode->{ $FileTag::K_NodeType } = "ELSE IF";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $logicDefineDesp;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $logicDespEndIdx + 1, $classEndBracketsIdx - 1 - $logicDespEndIdx);
	return &analysisContext($machSub, $currNode);
}

sub analysisWhole_LogicElse
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

    my $logicDespEndIdx = index($machSub, "{");
    my $logicDefineDesp = substr($machSub, 0, $logicDespEndIdx);

	# common
	$currNode->{ $FileTag::K_NodeType } = "ELSE";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $logicDefineDesp;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $logicDespEndIdx + 1, $classEndBracketsIdx - 1 - $logicDespEndIdx);
	return &analysisContext($machSub, $currNode);
}

sub analysisWhole_LogicSwitch
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

    my $logicDespEndIdx = index($machSub, "{");
    my $logicDefineDesp = substr($machSub, 0, $logicDespEndIdx);

	# common
	$currNode->{ $FileTag::K_NodeType } = "SWITCH";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $logicDefineDesp;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $logicDespEndIdx + 1, $classEndBracketsIdx - 1 - $logicDespEndIdx);
	return &analysisContext($machSub, $currNode);
}

sub analysisWhole_LogicWhile
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

    my $logicDespEndIdx = index($machSub, "{");
    my $logicDefineDesp = substr($machSub, 0, $logicDespEndIdx);

	# common
	$currNode->{ $FileTag::K_NodeType } = "WHILE";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $logicDefineDesp;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $logicDespEndIdx + 1, $classEndBracketsIdx - 1 - $logicDespEndIdx);
	return &analysisContext($machSub, $currNode);
}

sub analysisWhole_LogicFor
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

    my $logicDespEndIdx = index($machSub, "{");
    my $logicDefineDesp = substr($machSub, 0, $logicDespEndIdx);

	# common
	$currNode->{ $FileTag::K_NodeType } = "FOR";
	$currNode->{ $FileTag::K_NodeName } = "";
	$currNode->{ $FileTag::K_SelfData } = $logicDefineDesp;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $logicDespEndIdx + 1, $classEndBracketsIdx - 1 - $logicDespEndIdx);
	return &analysisContext($machSub, $currNode);
}

sub analysisWhole_LogicTry
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	# common
	$currNode->{ $FileTag::K_NodeType } = "TRY_TRY";
	$currNode->{ $FileTag::K_NodeName } = "";
}

sub analysisWhole_LogicCatch
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	# common
	$currNode->{ $FileTag::K_NodeType } = "TRY_CATCH";
	$currNode->{ $FileTag::K_NodeName } = "";
}

sub analysisWhole_LogicFinally
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	# common
	$currNode->{ $FileTag::K_NodeType } = "TRY_FINALLT";
	$currNode->{ $FileTag::K_NodeName } = "";
}


sub analysisWhole_VarDefine
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $isStatic = 0;
	my $isFinal = 0;
	my $varComplexType;
	my $variableName;

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
	# boolean isOk;
	# SparseArray<IntentCallback> mOutstandingIntents;
	# HashMap<Integer, String> mIntentErrors;
	# const HashMap<Integer, String> mIntentErrors;
	# const String[] mIntentErrors;
	my $semicoIdx = rindex($machSubTmp, ";");
	if ($semicoIdx >= 0) {
		if ($machSubTmp =~ m/(\S+)\s*;$/) {
			$variableName = $1;
			my $nameIdx = rindex($machSubTmp, $variableName);
			$varComplexType = substr($machSubTmp, 0, $nameIdx);
			$varComplexType = Util::stringTrim($varComplexType);
		}
	}
	else {
		print __LINE__.": [E]: format error\n";
	}

    # common
	$currNode->{ $FileTag::K_NodeType } = "VAR_DEFINE";
	$currNode->{ $FileTag::K_NodeName } = $variableName;
	$currNode->{ $FileTag::K_SelfData } = &fmtSelfData($machSub, $startSpace);

	$currNode->{ $FileTag::K_Scope } = "";
	$currNode->{ $FileTag::K_Static } = $isStatic;
	$currNode->{ $FileTag::K_Final } = $isFinal;

	# var
	$currNode->{ $FileTag::K_VarType } = $varComplexType;
	$currNode->{ $FileTag::K_VarName } = $variableName;

	my $selfDataTransed = "";
	if (1 eq $isStatic) { $selfDataTransed = $selfDataTransed."static "; }
	if (1 eq $isFinal) { $selfDataTransed = $selfDataTransed."const "; }
	my $varComplexTypeTransed = TransElastosType::transComplexVarDefineElastosType($varComplexType, 1);
	$selfDataTransed = $startSpace.$selfDataTransed.$varComplexTypeTransed." ".$variableName.";\n";
	$currNode->{ $FileTag::K_SelfDataTransed } = $selfDataTransed;

	ScopeStackManager::stackPushVar($variableName, $varComplexType);
}

sub analysisWhole_VarAssignment
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $startSpace = shift;
	my $funcContentsTransed = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $varComplexType;
	my $variableName;
	my $variableValue;
	my $variableTargetValue;

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
	$currNode->{ $FileTag::K_Scope } = "";

	my $assignLeft = new FileAnalysisStruct;
	my $assignRight = new FileAnalysisStruct;
	$currNode->{ $FileTag::K_VarAssL } = $assignLeft; # specify child node
	$currNode->{ $FileTag::K_VarAssR } = $assignRight;
	$assignLeft->{ $FileTag::K_ParNode } = $currNode;
	$assignRight->{ $FileTag::K_ParNode } = $currNode;
	&analysisWhole_VarAssignmentLeft($tag, $beforeEqualTmp, $parNode, $assignLeft);
	&analysisWhole_VarAssignmentRight($tag, $afterEqualTmp, $parNode, $assignRight, $assignLeft, $funcContentsTransed);
}

sub analysisWhole_VarAssignmentLeft
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $varComplexType = "";
	my $variableName = "";

    $machSubTmp = Util::stringTrim($machSubTmp);
	# likes or more:
	# boolean isOk;
	# SparseArray<IntentCallback> mOutstandingIntents;
	# HashMap<Integer, String> mIntentErrors;
	# const HashMap<Integer, String> mIntentErrors;
	# const String[] mIntentErrors;
	if ($machSubTmp =~ m/(\S+)\s*$/) {
		$variableName = $1;
		my $nameIdx = rindex($machSubTmp, $variableName);
		$varComplexType = substr($machSubTmp, 0, $nameIdx);
		$varComplexType = Util::stringTrim($varComplexType);
		ScopeStackManager::stackPushVar($variableName, $varComplexType);
	}

    # common
    $currNode->{ $FileTag::K_NodeTag } = $tag;
	$currNode->{ $FileTag::K_NodeType } = "VAR_ASSIGNMENT_LEFT";
	$currNode->{ $FileTag::K_NodeName } = $variableName;
	$currNode->{ $FileTag::K_SelfData } = $machSub;

	# var
	$currNode->{ $FileTag::K_VarType } = $varComplexType;
	$currNode->{ $FileTag::K_VarName } = $variableName;
}

sub analysisWhole_VarAssignmentRight
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;
	my $assignLeftNode = shift;
	my $funcContentsTransed = shift;

	my $machSubTmp = Util::stringTrim($machSub);
	my $machNoWarp = $machSubTmp;
	$machNoWarp =~ s/\n/ /g;

	# remove like "(Int32)" force conversion
	if ($machNoWarp =~ m/^\(\w+\)/) {
		$machNoWarp =~ s/^\(\w+\)//;
		$machNoWarp = Util::stringTrim($machNoWarp);
	}

	my $varComplexType;
	my $variableName;

	# is a single word or number
	if ($machNoWarp =~ m/^(\S+);$/) {
		my $right = $1;
		my $leftVarType = $assignLeftNode->{ $FileTag::K_VarType };
		my $leftVarName = $assignLeftNode->{ $FileTag::K_VarName };
		if ("" eq $leftVarType) {
			push @$funcContentsTransed, "$leftVarName = $right;";
		}
		else {
			my $leftVarTypeTransed = TransElastosType::transComplexVarDefineElastosType($leftVarType, 1);
			push @$funcContentsTransed, "$leftVarTypeTransed $leftVarName = $right;";
		}
	}

	# is a single func call has caller or no caller
	elsif ($machNoWarp =~ m/^(\w+)\((.*?)\);$/ || $machNoWarp =~ m/^(\w+)\.(\w+)\(.*?\);$/) {
		my $funcName = $1;
		my $parmsCont = $2;
		print __LINE__." into right func call\n";
		&doAnalysisAssignRightFuncCall($machSub, $parNode, $assignLeftNode, $funcContentsTransed);
		my $outStr = join "\n", @$funcContentsTransed;
		#print __LINE__." out right func call: outis:\n$outStr\n";
	}

	# var.var.var...
	elsif ($machNoWarp =~ m/^((\w|\d)+\.(\w|\d)+){1,};$/) {
		my $leftVarType = $assignLeftNode->{ $FileTag::K_VarType };
		my $leftVarName = $assignLeftNode->{ $FileTag::K_VarName };
		my $leftExpress = "";
		if ("" eq $leftVarType) {
			$leftExpress = "$leftVarName";
		}
		else {
			my $leftVarTypeTransed = TransElastosType::transComplexVarDefineElastosType($leftVarType, 1);
			$leftExpress = "$leftVarTypeTransed $leftVarName";
		}

		if ($machSubTmp =~ m/^(\w|\d)+/) {
			my $firstWord = $1;
			$machSubTmp =~ s/;$//;
			my @tmps = split(/\./, $machSubTmp);
			if (1 eq TransElastosType::isCarType($firstWord)) {
				$tmps[0] = "I".$firstWord;
				my $rightStr = join "::", @tmps;
				push @$funcContentsTransed, "$leftExpress = $rightStr;";
			}
			# is not car but first letter is upper, mey be is a class
			elsif (1 eq Util::isStrFirstUpper($firstWord)) {
				my $rightStr = join "::", @tmps;
				push @$funcContentsTransed, "$leftExpress = $rightStr;";
			}
			# first letter is lowwer, mey be is a var
			elsif (0 eq Util::isStrFirstUpper($firstWord)) {
				my ($find, $varType) = ScopeStackManager::findVarType($firstWord);
				if (1 eq TransElastosType::isAutoPtr($varType) || 1 eq TransElastosType::isPointer($varType)) {
					my @subs = split(/\./, $machSubTmp);
					my $rightStr = join "->", @subs;
					push @$funcContentsTransed, "$leftExpress = $rightStr;";
				}
				else {
					push @$funcContentsTransed, "$leftExpress = $machSubTmp;";
				}
			}
			else {
				push @$funcContentsTransed, "$leftExpress = $machSubTmp;";
			}
		}
	}

	else {
		print __LINE__." [FileAnalysisJavaFuncContent]: analysis var assign right no match, check it\n";
	}

    # common
    $currNode->{ $FileTag::K_NodeTag } = $tag;
	$currNode->{ $FileTag::K_NodeType } = "VAR_ASSIGNMENT_RIGHT";
	$currNode->{ $FileTag::K_SelfData } = $machSubTmp;
}

=pod
# muliple analysis func call
# start with:

var.funcName(***).funcName(...)***
class.funcName(***).funcName(...)***
funcName(***).funcName(...)***
new funcName(***).funcName(...)***      # seem new operate as func call

=cut
sub analysisComplex_FuncCall
{
	my $machSub = shift;
	my $parNode = shift;
	my $startSpace = shift;
	my $contentsTransed = shift;
	my $hasAssiLeft = shift;
	my $assiLeftName = shift;
	my $hasAssiLeftType = shift;
	my $assiLeftType = shift;
	my $hasCaller = shift;
	my $callerName = shift;

	# remove like "(Int32)" force conversion
	if ($machSub =~ m/^\(\w+\)/) {
		$machSub =~ s/^\(\w+\)//;
		$machSub = Util::stringTrim($machSub);
	}
	my $remainContent = $machSub;
	if (1 eq $hasAssiLeft && 0 eq $hasAssiLeftType) {
		my ($find, $type) = ScopeStackManager::findVarType($assiLeftName);
		if (1 eq $find) { $assiLeftType = $type; }
	}

	my $currCaller = "";
	my $callerDataType = "";
	my $callerLogicType = "";
	if ($remainContent =~ m/^(\w+)\.\w+\(/) {
		$currCaller = $1;
		$callerDataType = &getDataTypeFromCallerName($currCaller);
		$callerLogicType = &getLogicTypeFromCallerName($currCaller);
		$remainContent =~ s/^\w+\.//;
	}
	else {
		if (1 eq $hasCaller) {
			$currCaller = $callerName;
			$callerDataType = &getDataTypeFromCallerName($currCaller);
			$callerLogicType = &getLogicTypeFromCallerName($currCaller);
		}
	}

	# curr start of: "FuncName(" or "new Class("
	my $isEndFunc = 0;
	my ($hasReturn, $returnVarName, $returnDataType);
	$hasReturn = 0;
	$returnVarName = "";
	$returnDataType = "";
	while ("" ne $remainContent) {

		if ($remainContent =~ m/^\./) { $remainContent =~ s/^\.//; }
		last if (";" eq $remainContent);


		my $leftBracketsIdx = index($remainContent, "(");
		my ($isFind, $aimIdx) = Util::findBracketsEnd($remainContent, 0, "->", 0);
		last if (!($leftBracketsIdx >= 0 && 1 eq $isFind && $aimIdx > 0));

		my $eachFunc = substr($remainContent, 0, $aimIdx+1);
		$remainContent = substr($remainContent, $aimIdx+1);
		if ($remainContent =~ m/\./) { $isEndFunc = 0; }
		else { $isEndFunc = 1; }

		$returnVarName = "";
		$returnDataType = "";

		my @parms = ();
		push @parms, $eachFunc;
		push @parms, $parNode;
		push @parms, $contentsTransed;
		push @parms, $hasAssiLeft;
		push @parms, $assiLeftName;
		push @parms, $hasAssiLeftType;
		push @parms, $assiLeftType;
		push @parms, $hasCaller;
		push @parms, $currCaller;
		push @parms, $callerDataType;
		push @parms, $callerLogicType;
		push @parms, $isEndFunc;
		push @parms, \$returnVarName;
		push @parms, \$returnDataType;
		&analysisComplex_EachCall(@parms);
		if ("" ne $returnVarName) {
			$currCaller = $returnVarName;
			$callerDataType = $returnDataType;
			$callerLogicType = "VAR";
		}
	}
	return ($hasReturn, $returnVarName);
}

# input: just like "FuncName(***)"
sub analysisComplex_EachCall
{
	my @params = @_;

	# new XXX(
	if ($params[0] =~ m/^new\s+/) {
		&analysisComplex_EachCall_new(@params);
	}
	elsif ($params[0] =~ m/^(\w+)\s*\(/) {
		&analysisComplex_EachCall_common(@params);
	}
}

# input: just like "FuncName(***)"
sub analysisComplex_EachCall_new
{
	my $machSub = shift;
	my $parNode = shift;
	my $contentsTransed = shift;
	my $hasAssiLeft = shift;
	my $assiLeftName = shift;
	my $hasAssiLeftType = shift;
	my $assiLeftType = shift;
	my $hasCaller = shift;
	my $caller = shift;
	my $callerDataType = shift; # such as "IContext", "AutoPtr<ILoadUrl>"
	my $callerLogicType = shift; # "", "VAR", "CLASS"(static)
	my $isEndFunc = shift;
	my $returnVarNamePtr = shift;
	my $returnDataTypePtr = shift;
	$$returnVarNamePtr = "";
	$$returnDataTypePtr = "";

	my $leftVarType = "";
	my $leftVarName = "";
	my $leftVarTypeTransed = "";
	if (1 eq $isEndFunc) {
		$assiLeftType = TransElastosType::transComplexVarDefineElastosType($assiLeftType, 1);
	}

	# get new what ?
	if ($remainContent =~ m/^new\s+(\w|\d)+\s*\(/) {
		my $className = $1;
		my ($paramFind, @paramsInfo) = &obtFuncCallParamContent($remainContent);
		my $paramCnt = @paramsInfo;
		my ($find, $funcPosType, $funcReturn, $params) = &findFuncDefineAnywhere($parNode, $className, $className, $paramCnt);
		if (1 eq $find) {
			my $leftBrackIdx = index($remainContent, "(");
			my $rightBrackIdx = rindex($remainContent, ")");
			my $funcParamsContent = Util::stringTrim(substr($remainContent, $leftBrackIdx+1, $rightBrackIdx-$leftBrackIdx-1));

			# has no param
			if ("" eq $funcParamsContent) {
				if (1 eq $isEndFunc && 1 eq $hasAssiLeft) {
					if (1 eq $hasAssiLeftType) {
						my $transType = TransElastosType::transComplexVarDefineElastosType($assiLeftType, 1);
						if (1 eq TransElastosType::isCarType($className)) {
							push @$contentsTransed, "$transType $assiLeftName;";
							if ("" eq $assiLeftName) {
								push @$contentsTransed, "$className::New(&$assiLeftName);";
							}
							else {
								push @$contentsTransed, "$className::New($newFuncParamContent, &$assiLeftName);";
							}
						}
						else {
							push @$contentsTransed, "AutoPtr<$transType> $assiLeftName = new $className();";
						}
					}
					else {
						if (1 eq TransElastosType::isCarType($assiLeftType)) {
							push @$contentsTransed, "C$className::New(&$newVar);";
						}
						else {
							push @$contentsTransed, "$assiLeftName = new $className();";
						}
					}
				}
				else {
					my $newVar = lcfirst($className);
					$newVar = ScopeStackManager::buildSpecifyVar($newVar);
					my $dstCarType = "";
					if (1 eq TransElastosType::isCarType($className, \$dstCarType)) {
						ScopeStackManager::stackPushVar($newVar, "AutoPtr<$dstCarType>");
						push @$contentsTransed, "AutoPtr<$dstCarType> $newVar;";
						push @$contentsTransed, "C$className::New(&$newVar);";
						$$returnVarNamePtr = $newVar;
						$$returnDataTypePtr = "AutoPtr<$dstCarType>";
					}
					else {
						ScopeStackManager::stackPushVar($newVar, "AutoPtr<$className>");
						push @$contentsTransed, "AutoPtr<$className> $newVar = new $className();";
						$$returnVarNamePtr = $newVar;
						$$returnDataTypePtr = "AutoPtr<$className>";
					}
				}
			}
			# has param
			else {
				my $funcParsms = Util::stringSplitParamsContent($funcParamsContent);
				my $funcName = $className;
				my $currParamCnt = @$funcParsms;
				my $currParamIdx = 0;

				my @paramSelfContents = ();
				foreach my $item (@$funcParsms) {
					my @params = ();

					push @params, $item;
					push @params, $parNode;
					push @params, $contentsTransed;
					push @params, $hasAssiLeft;
					push @params, $assiLeftName;
					push @params, $hasAssiLeftType;
					push @params, $assiLeftType;
					push @params, $hasCaller;
					push @params, $currCaller;
					push @params, $callerDataType;
					push @params, $callerLogicType;
					push @params, $isEndFunc;
					push @params, $returnVarNamePtr;
					push @params, $returnDataTypePtr;
					push @params, $funcName;
					push @params, $currParamCnt;
					push @params, $currParamIdx++;
					my @paramSingleSelfContents = ();
					push @params, \@paramSingleSelfContents;
					&analysisComplex_EachCall_param(@params);

					# current func parm analysis end
					if ($currParamIdx eq @$funcParsms) {
						push @paramSelfContents, @paramSingleSelfContents;
						my $newFuncParamContent = join ", ", @paramSelfContents;

						if (1 eq $isEndFunc) {
							if (1 eq $hasAssiLeft) {
								if (1 eq $hasAssiLeftType) {
									my $transType = TransElastosType::transComplexVarDefineElastosType($assiLeftType, 1);
									if (1 eq TransElastosType::isCarType($className)) {
										push @$contentsTransed, "$transType $assiLeftName;";
										if ("" eq $assiLeftName) {
											push @$contentsTransed, "$className::New(&$assiLeftName);";
										}
										else {
											push @$contentsTransed, "$className::New($newFuncParamContent, &$assiLeftName);";
										}
									}
									else {

									}


								}
								else {
									my $transType = TransElastosType::transComplexVarDefineElastosType($assiLeftType, 1);
									push @$contentsTransed, "$assiLeftName = new $className($newFuncParamContent);";
								}
							}
							else {
								my $newVar = lcfirst($className);
								$newVar = ScopeStackManager::buildSpecifyVar($newVar);
								ScopeStackManager::stackPushVar($newVar, "AutoPtr<$className>");
								push @$contentsTransed, "AutoPtr<$className> $newVar = new $className($newFuncParamContent);";
							}
						}
						else {
							my $newVar = lcfirst($className);
							$newVar = ScopeStackManager::buildSpecifyVar($newVar);
							ScopeStackManager::stackPushVar($newVar, "AutoPtr<$className>");
							push @$contentsTransed, "AutoPtr<$className> $newVar = new $className($newFuncParamContent);";
						}
					}
					else {
						push @paramSelfContents, @paramSingleSelfContents;
					}
				}
			}
		}
		else {
			print __LINE__." new $className cannot find class $className\n";
			<STDIN>;
		}
	}
	elsif ($remainContent =~ m/^new\s+(\w|\d)+\s*\(.*?\)\s*{/) {
		print __LINE__." new XXX {, donot realization yet\n";
		<STDIN>;
	}
	else {
		print __LINE__." else , donot realization yet\n";
		<STDIN>;
	}
}

# input: just like "FuncName(***)"
sub analysisComplex_EachCall_common
{
	my $machSub = shift;
	my $parNode = shift;
	my $contentsTransed = shift;
	my $hasAssiLeft = shift;
	my $assiLeftName = shift;
	my $assiLeftType = shift;
	my $hasCaller = shift;
	my $caller = shift;
	my $callerDataType = shift; # such as "IContext", "AutoPtr<ILoadUrl>"
	my $callerLogicType = shift; # "", "VAR", "CLASS"(static)
	my $isEndFunc = shift;
	my $returnVarNamePtr = shift;
	my $returnDataTypePtr = shift;

	my ($returnVarName, $returnDataType);
	$returnVarName = "";
	$returnDataType = "";

	my $leftVarType = "";
	my $leftVarName = "";
	my $leftVarTypeTransed = "";
	if (1 eq $isEndFunc) {
		$assiLeftType = TransElastosType::transComplexVarDefineElastosType($assiLeftType, 1);
	}

	# new XXX(
	if ($remainContent =~ m/^new\s+(\w|\d)+\s+\(/) {
		my $className = $1;
		push @$contentsTransed, "AutoPtr<>"


	}

	elsif ($machSub =~ m/^(\w+)\s*\(/) {
		my $funcName = $1;
		my $ucFuncName = ucfirst($funcName);

		my $leftBrackIdx = index($machSub, "(");
		my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0, "->", $leftBrackIdx);
		my $funcParmsContent = "";
		my @paramsExteneralExpress = ();
		my @paramsTransed = ();
		my $paramsTransedStr = "";
		if (1 eq $isFind) {
			$funcParmsContent = substr($machSub, $leftBrackIdx+1, $aimIdx - $leftBrackIdx - 1);
			$funcParmsContent = Util::stringTrim($funcParmsContent);
			if ("" ne $funcParmsContent) {
				&doAnalysisAssignRightSubEachFuncCallParms($funcParmsContent, $parNode, \@paramsExteneralExpress, \@paramsTransed);
				$paramsTransedStr = join ", ", @paramsTransed;
			}
		}
		else {
			print __LINE__." doAnalysisFuncCall: else\n";
			<STDIN>;
		}

		# func name start with get***
		# getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		#if ($funcName =~ m/^get/) {
			if (1 eq $hasCaller) {
				if ("VAR" eq $callerLogicType) {
					my $callerRealDataType = &obtRealDataType($callerDataType);
					$callerRealDataType =~ s/^I//;

					# AutoPtr is just a shell that donot be needed, remove out first.
					if (1 eq TransElastosType::isAutoPtr($callerRealDataType)) {
						$callerRealDataType =~ s/^AutoPtr<//;
						$callerRealDataType =~ s/>$//;
						$callerRealDataType = Util::stringTrim($callerRealDataType);
					}

					if (1 eq TransElastosType::isCarType($callerRealDataType)) {
						my $carFileName = $callerRealDataType.".car";
						#print __LINE__." analysis immediately\n";
						#<STDIN>;
						my ($analyCarOk, $realCarName) = FileAnalysisCar::obtFuzzyCarName($carFileName);
						if (0 eq $analyCarOk) {
							die "can not find fuzzy $realCarName, die\n";;
						}

						my $carName = "I".$callerRealDataType;
						my $ucFuncName = ucfirst($funcName);

						my @parmsContent = split(/,/, $funcParmsContent);
						my $parmCnt = @parmsContent;

						my ($find, $funcNode) = FileAnalysisCar::obtSpecifyFuncInCurrCar($ucFuncName, $parmCnt);
						if (0 eq $find) {
							die "can not find func $ucFuncName, die\n";;
						}

						my $params = $funcNode->{ $FileTag::K_Params };
						my $outputParm = $params->[@$params - 1];
						my $outputParamType = $outputParm->{ $FileTag::K_ParamType };
						print __LINE__." \$outputParamType=$outputParamType\n";

						# parm type end with "**" it may be Car type
						if ($outputParamType =~ m/\*{2,}$/) {
							# but this car type may cannot find ind cur java import express;
							# such as IInterface** similar base type
							# if it is the end func, use out parm type in func output
							# but return type use the left var type
							$outputParamType =~ s/\**$//;

							if (1 eq $isEndFunc) {
								#print __LINE__." is end func\n";
								if ("" eq $leftVarTypeTransed) {
									if ("" eq $paramsTransedStr) {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$caller->$ucFuncName(($outputParamType**)&$leftVarName);";
									}
									else {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, ($outputParamType**)&$leftVarName);";
									}
								}
								else {
									if ("" eq $paramsTransedStr) {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$leftVarTypeTransed $leftVarName;";
										push @$contentsTransed, "$caller->$ucFuncName(($outputParamType**)&$leftVarName);";
									}
									else {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$leftVarTypeTransed $leftVarName;";
										push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, ($outputParamType**)&$leftVarName);";
									}
								}
								$returnVarName = $leftVarName;
								if ($returnVarName !~ m/^I/) {
									$returnVarName = $leftVarName;
									$returnDataType = $leftVarTypeTransed;
								}
							}
							else {
								my $var = lcfirst($callerRealDataType);
								push @$contentsTransed, @paramsExteneralExpress;
								push @$contentsTransed, "AutoPtr<$carName> $var;\n";
								if ("" eq $paramsTransedStr) {
									push @$contentsTransed, "$caller->$ucFuncName(($carName**)&$var);";
								}
								else {
									push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, ($carName**)&$var);";
								}

								$returnVarName = $outputParamType;
								if ($returnVarName !~ m/^I/) {
									$returnVarName = $var;
									$returnDataType = "I".$outputParamType;
								}
							}
						}
						elsif (1 eq TransElastosType::isArrayOf($outputParamType)) {
							my $var = lcfirst($callerRealDataType);
							my $leftSharpBrackIdx = index($outputParamType, "<");
							my $rightSharpBrackIdx = rindex($outputParamType, ">");
							my $innerArrayOf = substr($outputParamType, $leftSharpBrackIdx+1, $rightSharpBrackIdx-$leftSharpBrackIdx-1);
							my $transInnerArrayOf = "";
							if ($innerArrayOf =~ m/\*$/) {
								$innerArrayOf =~ s/\**$//;
								$transInnerArrayOf = "AutoPtr<".$innerArrayOf.">";
								push @$contentsTransed, @paramsExteneralExpress;
								push @$contentsTransed, "AutoPtr< $transInnerArrayOf > $var;";
							}
							else {
								$transInnerArrayOf = $innerArrayOf;
								push @$contentsTransed, @paramsExteneralExpress;
								push @$contentsTransed, "AutoPtr<$transInnerArrayOf> $var;";
							}

							if ("" eq $paramsTransedStr) {
								push @$contentsTransed, "$caller->$ucFuncName(&$var);";
							}
							else {
								push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, &$var);";
							}

							if ($returnVarName !~ m/^I/) {
								$returnVarName = $var;
								$returnDataType = "ArrayOf";
							}
						}
						else {
							my $var = $funcName;
							$var =~ s/^get//;
							$var = lcfirst($var);
							push @$contentsTransed, @paramsExteneralExpress;
							push @$contentsTransed, "$outputParamType $var;";

							if ("" eq $paramsTransedStr) {
								push @$contentsTransed, "$caller->$ucFuncName(&$var);";
							}
							else {
								push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, &$var);";
							}

							if ($returnVarName !~ m/^I/) {
								$returnVarName = $var;
								$returnDataType = "$outputParamType";
							}
						}
					}
					elsif (1 eq TransElastosType::isArrayOf($callerRealDataType)) {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
					}
					else {
						print __LINE__." common var call getFunc, is it will exists?\n";
						<STDIN>;
					}
				}
				elsif ("CLASS" eq $callerLogicType) {
					push @$contentsTransed, @paramsExteneralExpress;
					push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
				}
			}
			# no caller
			else {
				# is getCar: such like getContext((Int32)a)
				# to:
				# AutoPtr<IContext> context;
				# GetContext(a, (IContext**)&context);
				my $getWhat = $funcName;
				$getWhat =~ s/^get//;
				if (1 eq $isEndFunc) {
					my $var = lcfirst($getWhat);
					if (1 eq TransElastosType::isCarType($getWhat) || 1 eq TransElastosType::isCarType($leftVarTypeTransed)) {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "AutoPtr<$leftVarTypeTransed> $var;";

						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$ucFuncName(($leftVarTypeTransed**)&$var);";
						}
						else {
							push @$contentsTransed, "$ucFuncName($paramsTransedStr, ($leftVarTypeTransed**)&$var);";
						}
					}
					else {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "$leftVarTypeTransed $var;";
						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$ucFuncName(&$var);";
						}
						else {
							push @$contentsTransed, "$ucFuncName($paramsTransedStr, &$var);";
						}
					}
				}
				# func isnot end
				else {
					# first need search func in curr class
					&obtCurrFuncOutFuncDefineInCurrMainClassAndSaveTmp($parNode);
					my $mayRet = "";
					if (1 eq &findFuncDefineInObtOutFuncsDefineInTmp($ucFuncName, \$mayRet)) {
						my $retTransed = TransElastosType::transComplexReturnElastosType($mayRet, 1);
						my $var = lcfirst($getWhat);
						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$retTransed $var = $ucFuncName();";
						}
						else {
							push @$contentsTransed, "$retTransed $var = $ucFuncName($paramsTransedStr);";
						}
						$returnVarName = $var;
						$returnDataType = $retTransed;
					}
					elsif (1 eq TransElastosType::isCarType($getWhat)) {
						my $var = lcfirst($getWhat);
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "AutoPtr<I$getWhat> $var;";
						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$ucFuncName((I$getWhat**)&$var);";
						}
						else {
							push @$contentsTransed, "$ucFuncName($paramsTransedStr, (I$getWhat**)&$var);";
						}
						$returnVarName = $var;
						$returnDataType = $getWhat;
					}

					else {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
					}
				}
			}
		#}
=pod
		# else func, ucfirst
		else {
			if (1 eq $isEndFunc) {
				my $express = "";
				if ("" eq $leftVarTypeTransed) {
					$express = "$leftVarName = $ucFuncName($paramsTransedStr);";
				}
				else {
					$express = "$leftVarTypeTransed $leftVarName = $ucFuncName($paramsTransedStr);";
				}

				push @$contentsTransed, @paramsExteneralExpress;
				push @$contentsTransed, $express;
			}
			else {
				push @$contentsTransed, @paramsExteneralExpress;
				push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
			}

		}
=cut

	}




	my $machSub = shift;
	my $parNode = shift;
	my $contentsTransed = shift;
	my $hasAssiLeft = shift;
	my $assiLeftName = shift;
	my $assiLeftType = shift;
	my $hasCaller = shift;
	my $caller = shift;
	my $callerDataType = shift; # such as "IContext", "AutoPtr<ILoadUrl>"
	my $callerLogicType = shift; # "", "VAR", "CLASS"(static)
	my $isEndFunc = shift;
	my $returnVarNamePtr = shift;
	my $returnDataTypePtr = shift;
	$$returnVarNamePtr = "";
	$$returnDataTypePtr = "";

	my $leftVarType = "";
	my $leftVarName = "";
	my $leftVarTypeTransed = "";
	if (1 eq $isEndFunc) {
		$assiLeftType = TransElastosType::transComplexVarDefineElastosType($assiLeftType, 1);
	}

	# get new what ?
	if ($remainContent =~ m/^new\s+(\w|\d)+\s*\(/) {
		my $className = $1;
		my ($paramFind, @paramsInfo) = &obtFuncCallParamContent($remainContent);
		my $paramCnt = @paramsInfo;
		my ($find, $funcPosType, $funcReturn, $params) = &findFuncDefineAnywhere($parNode, $className, $className, $paramCnt);
		if (1 eq $find) {
			my $leftBrackIdx = index($remainContent, "(");
			my $rightBrackIdx = rindex($remainContent, ")");
			my $funcParamsContent = Util::stringTrim(substr($remainContent, $leftBrackIdx+1, $rightBrackIdx-$leftBrackIdx-1));
			if ("" ne $funcParamsContent) {
				my $funcParsms = Util::stringSplitParamsContent($funcParamsContent);
				my $funcName = $className;
				my $currParamCnt = @$funcParsms;
				my $currParamIdx = 0;

				my @paramSelfContents = ();
				foreach my $item (@$funcParsms) {
					my @params = ();

					push @params, $item;
					push @params, $parNode;
					push @params, $contentsTransed;
					push @params, $hasAssiLeft;
					push @params, $assiLeftName;
					push @params, $assiLeftType;
					push @params, $hasCaller;
					push @params, $currCaller;
					push @params, $callerDataType;
					push @params, $callerLogicType;
					push @params, $isEndFunc;
					push @params, $returnVarNamePtr;
					push @params, $returnDataTypePtr;
					push @params, $funcName;
					push @params, $currParamCnt;
					push @params, $currParamIdx++;
					my @paramSingleSelfContents = ();
					push @params, \@paramSingleSelfContents;
					&analysisComplex_EachCall_param(@params);
					if ($currParamIdx eq @$funcParsms) {
						push @paramSelfContents, @paramSingleSelfContents;
						my $newFuncParamContent = join ", ", @paramSelfContents;
						my $newVar = lcfirst($className);
						$newVar = ScopeStackManager::buildSpecifyVar($newVar);
						push @$contentsTransed, "AutoPtr<$className> $newVar = new $className($newFuncParamContent);";
						ScopeStackManager::stackPushVar($newVar, "AutoPtr<$className>");
					}
					else {
						push @paramSelfContents, @paramSingleSelfContents;
					}
				}
			}
		}
		else {
			print __LINE__." new $className cannot find class $className\n";
			<STDIN>;
		}
	}
	elsif ($remainContent =~ m/^new\s+(\w|\d)+\s*\(.*?\)\s*{/) {
		print __LINE__." new XXX {, donot realization yet\n";
		<STDIN>;
	}
	else {
		print __LINE__." else , donot realization yet\n";
		<STDIN>;
	}

	return ($returnVarName, $returnDataType);
}


# input: just like "FuncName(***)"
sub analysisComplex_EachCall_param
{
	my $machSub = shift;		# single param
	my $parNode = shift;
	my $contentsTransed = shift;	# just only param self
	my $hasAssiLeft = shift;
	my $assiLeftName = shift;
	my $hasAssiLeftType = shift;
	my $assiLeftType = shift;
	my $hasCaller = shift;
	my $caller = shift;
	my $callerDataType = shift; # such as "IContext", "AutoPtr<ILoadUrl>"
	my $callerLogicType = shift; # "", "VAR", "CLASS"(static)
	my $isEndFunc = shift;
	my $returnVarNamePtr = shift;
	my $returnDataTypePtr = shift;
	my $funcName = shift;
	my $currParamCnt = shift;
	my $currParamIdx = shift;	# the index of curr param in whole params
	my $paramSelfTransed = shift;	# may external info that isnot param self

	# single is donot need translate
	if ($machSub =~ m/^(\w|\d)+$/) {
		# null is a multiple means,
		# if is a pointer, translate it to NULL
		# if is a String, translate it to ""
		# but is need more info so translate it as NULL temporary
		if ($machSub eq "null") {
			my ($parmFind, $parmType) = &findFuncParamType($parNode, $caller, $funcName, $currParamCnt, $currParamIdx);
			if (1 eq $parmFind) {
				if ($parmType eq "String") { push @$paramSelfTransed, "String(\"\")"; }
				elsif ($parmType =~ m/^Int\d+$/) { push @$paramSelfTransed, "0"; }
				elsif ($parmType =~ m/^Float$/) { push @$paramSelfTransed, "0"; }
				else { push @$paramSelfTransed, "NULL"; }
			}
			else { push @$paramSelfTransed, "NULL"; }
		}
		else {
			push @$paramSelfTransed, $machSub;
		}
	}
	# func call, may be many times call
	# var.Func()
	# Func()
	# new Class()
	elsif ($machSub =~ m/^(\w|\d)+\.\(.*?\)/ || $machSub =~ m/^(\w|\d)+\(/ || $machSub =~ m/^\s*new\s+(\w|\d)+/) {
		my $subHasCaller = 0;
		my $subCallerName = "";
		my $subIsEndFunc = 0;
		my $subHasReturn = 0;
		my $subReturnVarName = "";
		my $subReturnDataType = "";
		my $subHasAssiLeft = 0;
		my $subAssiLeftName = "";
		my $subAssiLeftType = "";
		my $subCallerDataType = "";
		my $subCallerLogicType = "";

		if ($machSub =~ m/^(\w|\d)+\.\(.*?\)/) {
			$subHasCaller = 1;
			$subCallerName = $1;
			$machSub =~ s/^(\w|\d)+\.//;

			my ($varFind, $varType) = &getDataTypeFromCallerName($subCallerName);
			if (1 eq $varFind) { $subCallerDataType = $varType; }
			($varFind, $varType) = &getLogicTypeFromCallerName($subCallerName);
			if (1 eq $varFind) { $subCallerLogicType = $varType; }
		}

		my $subFuncCalls = Util::stringSplitFuncContinueCallContent($machSub);
		my $funcCallIdx = 0;
		foreach my $subEachCall (@$subFuncCalls) {
			if ($funcCallIdx eq @$subFuncCalls - 1) { $subIsEndFunc = 1; }
			else { $subIsEndFunc = 0; }
			my @parms = ();
			push @parms, $subEachCall;
			push @parms, $parNode;
			push @parms, $contentsTransed;
			push @parms, $subHasAssiLeft;
			push @parms, $subAssiLeftName;
			push @parms, $subAssiLeftType;
			push @parms, $subHasCaller;
			push @parms, $subCallerName;
			push @parms, $subCallerDataType;
			push @parms, $subCallerLogicType;
			push @parms, $subIsEndFunc;
			push @parms, \$subReturnVarName;
			push @parms, \$subReturnDataType;
			&analysisComplex_EachCall(@parms);
			if ("" eq $$subReturnVarName) {
				$subHasCaller = 0;
				$subCallerName = "";
				$subCallerDataType = "";
				$subCallerLogicType = "";
			}
			else {
				$subHasCaller = 1;
				$subCallerName = $$subReturnVarName;
				$subCallerDataType = "";
				$subCallerLogicType = "";
				($varFind, $varType) = &getDataTypeFromCallerName($subCallerName);
				if (1 eq $varFind) { $subCallerDataType = $varType; }
				($varFind, $varType) = &getLogicTypeFromCallerName($subCallerName);
				if (1 eq $varFind) { $subCallerLogicType = $varType; }
			}
		}
	}
	# var.var, or maybe more as: var.var.$machSub
	elsif ($machSub =~ m/^(\w+)\.\w+/ && $machSub !~ m/^(\w+)\.\w+\(/) {
		my $firstWord = $1;
		if (1 eq TransElastosType::isCarType($firstWord)) {
			my @subs = split(/\./, $machSub);
			my $firstItem = $subs[0];
			$firstItem = "I".$firstItem;
			$subs[0] = $firstItem;
			my $tmp = join "::", @subs;
			push @$paramSelfTransed, $tmp;
		}
		# is not car but first letter is upper, may be a class
		elsif (1 eq Util::isStrFirstUpper($firstWord)) {
			my @subs = split(/\./, $machSub);
			my $tmp = join "::", @subs;
			push @$paramSelfTransed, $tmp;
		}
		# is not car and first letter isnot upper too, may be a var
		elsif (0 eq Util::isStrFirstUpper($firstWord)) {
			my ($find, $varType) = ScopeStackManager::findVarType($firstWord);
			if (1 eq TransElastosType::isAutoPtr($varType) || 1 eq TransElastosType::isPointer($varType)) {
				my @subs = split(/\./, $machSub);
				my $tmp = join "->", @subs;
				push @$paramSelfTransed, $tmp;
			}
			else {
				push @$paramSelfTransed, $machSub;
			}
		}
		else {
			push @$paramSelfTransed, $machSub;
		}
	}
	else {
		push @$paramSelfTransed, $machSub;
	}
}


sub analysisCurrWholeTag
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
	}

	# 4: check end with ";" or "};" or ");"
	if (0 == $checkOk) {
		my ($endSymbol, $endSymIdx) = Util::obtEndSymbol($inputHasWrap);
		#print __LINE__." \$endSymbol=$endSymbol, \$endSymIdx=$endSymIdx\n";

		if (";" eq $endSymbol) {
			# remove force trans first
			if ($inputHasWrap =~ m/^(\(\w+\))/) {
				my $force = $1;
				$inputHasWrap =~ s/^$force//;
				$inputNoWrap =~ s/^$force//;
			}
			$machSub = substr($inputHasWrap, 0, $endSymIdx+1);
			$stayContent = substr($inputHasWrap, $endSymIdx+1);

			#print __LINE__." \$machSub=[$machSub]\n";
			#print __LINE__." \$stayContent=[$stayContent]\n";

			my $firstSemicIdx = index($inputHasWrap, ";");
			my $firstSmallBracketIdx = index($inputHasWrap, "(");
			my $firstBigBracketIdx = index($inputHasWrap, "{");
			my $subNoWrapTmp = substr($inputNoWrap, 0, $endSymIdx+1);
			my $subHasWrapTmp = substr($inputHasWrap, 0, $endSymIdx+1);
			#print __LINE__." \$subNoWrapTmp=$subNoWrapTmp\n";
			#print __LINE__." \$subHasWrapTmp=$subHasWrapTmp\n";

			my @firstIdxs;
			push @firstIdxs, $firstSemicIdx;
			push @firstIdxs, $firstSmallBracketIdx;
			push @firstIdxs, $firstBigBracketIdx;

			my $usefullMinIdx = Util::usefullMin(\@firstIdxs, -1);
			my $equalIdx = index($subNoWrapTmp, "=");

			# varible assignment
			if ($equalIdx >= 0 && $equalIdx < $usefullMinIdx) {
				$tag = $FileTag::DC_var_assignment;
		    	$checkOk = 1;
		    	$checkMachIdx = 4;
			}
			# may be varible or function
			else {
				# may be a func
				if ($subNoWrapTmp =~ m/\w+\(/ || $subNoWrapTmp =~ m/^\w+\.\w+\(/) {
					if (1 eq $parNode->isCurrUpwardInType("FUNC")) {
						$tag = $FileTag::DC_function_call;
		    			$checkOk = 1;
		    			$checkMachIdx = 4;
					}
				}
				elsif ($subNoWrapTmp =~ m/\s*return\s+/) {
					$tag = $FileTag::DC_return;
	    			$checkOk = 1;
	    			$checkMachIdx = 4;
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
			if ($leftBracketsSub =~ m/else\s+if\s+/) {
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
			elsif ($leftBracketsSub =~ m/try\s+/) {
				$tag = $FileTag::DC_logic_try;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/catch\s+/) {
				$tag = $FileTag::DC_logic_catch;
		    	$checkOk = 1;
		    	$checkMachIdx = 5;
			}
			elsif ($leftBracketsSub =~ m/finally\s+/) {
				$tag = $FileTag::DC_logic_finally;
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
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

	my $tarClassName = "";
	my $currClassName = "";
	$machSub =~ s/^\s*?new\s+//g;
	if ($machSub =~ m/^(.*?)\(/) {
		$tarClassName = $1;
		$tarClassName =~ s/\./::/g;
		$currClassName = &buildInnerClassName($tarClassName);
		$machSub =~ s/^$tarClassName\s*//g;

		# such as: InnerCallable<String[]>
		# bacause car has no template
		if ($currClassName =~ m/^(\w+|\d+)/) {
			$currClassName = $1;
		}
	}
	my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0, "->", 0);
	my $constrFuncParm = substr($machSub, 1, $aimIdx - 1);
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

sub doAnalysisWhole_FuncCall
{
	my $machSub = shift;
	my $parNode = shift;
	my $startSpace = shift;
	my $funcCallContentTransed = shift;

	# remove like "(Int32)" force conversion
	if ($machSub =~ m/^\(\w+\)/) {
		$machSub =~ s/^\(\w+\)//;
	}

	my $remainContent = $machSub;
	my $currCaller = "";
	my $callerDataType = "";
	my $callerLogicType = "";
	if ($remainContent =~ m/^(\w+)\.\w+\(/) {
		$currCaller = $1;
		$remainContent =~ s/^\w+\.//;
		if (1 eq Util::isStrFirstUpper($currCaller)) {
			$callerLogicType = "CLASS";
			$callerDataType = $currCaller;
		}
		else {
			$callerLogicType = "VAR";
			# find var in var stack
			my ($find, $type) = ScopeStackManager::findVarType($currCaller);
			if ("" ne $type) {
				$callerDataType = $type;
			}
			else {
				print __LINE__." doAnalysisFuncCall: $currCaller may be a var but cannot find its type\n";
				<STDIN>;
				return;
			}
		}
	}
	# curr start of: "FuncName("
	while ("" ne $remainContent) {
		if ($remainContent =~ m/^\./) { $remainContent =~ s/^\.//; }
		last if (";" eq $remainContent);
		my $leftBracketsIdx = index($remainContent, "(");
		my ($isFind, $aimIdx) = Util::findBracketsEnd($remainContent, 0, "->", 0);
		last if (!($leftBracketsIdx >= 0 && 1 eq $isFind && $aimIdx > 0));
		my $eachFunc = substr($remainContent, 0, $aimIdx+1);

		my @funcCallContentTransed = ();
		my $hasCaller = 0;
		if ("" ne $currCaller) { $hasCaller = 1; }
		my ($return, $returnDataType) = &doAnalysisWhole_SubEachFuncCall($eachFunc, $parNode, \@funcCallContentTransed, $hasCaller, $currCaller, $callerDataType, $callerLogicType);
		if ("" ne $return) {
			$currCaller = $return;
			$callerDataType = $returnDataType;
			$callerLogicType = "VAR";
		}

		push @$funcCallContentTransed, @funcCallContentTransed;
		$remainContent = substr($remainContent, $aimIdx+1);
	}
}

# input: just like "FuncName(***)"
sub doAnalysisWhole_SubEachFuncCall
{
	my $machSub = shift;
	my $parNode = shift;
	my $funcCallContentTransed = shift;
	my $hasCaller = shift;
	my $caller = shift;
	my $callerDataType = shift; # such as "IContext", "AutoPtr<ILoadUrl>"
	my $callerLogicType = shift; # "", "VAR", "CLASS"(static)

	my ($return, $returnDataType);
	$return = "";
	$returnDataType = "";

	if ($machSub =~ m/^(\w+)\s*\(/) {
		my $funcName = $1;
		my $ucFuncName = ucfirst($funcName);

		my $leftBrackIdx = index($machSub, "(");
		my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0, "->", $leftBrackIdx);
		my $funcParmsContent = "";
		my @paramsExteneralExpress = ();
		my @paramsTransed = ();
		my $paramsTransedStr = "";
		if (1 eq $isFind) {
			$funcParmsContent = substr($machSub, $leftBrackIdx+1, $aimIdx - $leftBrackIdx - 1);
			&doAnalysisWhole_SubEachFuncCallParms($funcParmsContent, $parNode, \@paramsExteneralExpress, \@paramsTransed);
			$paramsTransedStr = join ", ", @paramsTransed;
		}
		else {
			print __LINE__." doAnalysisFuncCall: else\n";
			<STDIN>;
		}

		# has no caller usually
		if ($funcName eq "super") {
			my $classNode = $parNode->getSpecifyTypeNodeUpwardRecursive("CLASS");
			if (exists ($classNode->{ $FileTag::K_Parents })) {
				my $pars = $classNode->{ $FileTag::K_Parents };
				my $firstParName = $pars->[0]; # java only can extents one class, else may be interface
				push @$funcCallContentTransed, @paramsExteneralExpress;
				push @$funcCallContentTransed, "$firstParName($paramsTransedStr);";
			}
			else {
				push @$funcCallContentTransed, @paramsExteneralExpress;
				push @$funcCallContentTransed, "$ucFuncName($paramsTransedStr);";
			}
		}

		# func name start with set**,
		elsif ($funcName =~ m/^set/) {
			push @$funcCallContentTransed, @paramsExteneralExpress;
			push @$funcCallContentTransed, "$ucFuncName($paramsTransedStr);\n";
		}

		# func name start with get***
		# getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		elsif ($funcName =~ m/^get/) {
			if (1 eq $hasCaller) {
				if ("VAR" eq $callerLogicType) {
					my $callerRealDataType = &obtRealDataType($callerDataType);
					$callerRealDataType =~ s/^I//;

					# AutoPtr is just a shell that donot be needed, remove out first.
					if (1 eq TransElastosType::isAutoPtr($callerRealDataType)) {
						$callerRealDataType =~ s/^AutoPtr<//;
						$callerRealDataType =~ s/>$//;
						$callerRealDataType = Util::stringTrim($callerRealDataType);
					}

					if (1 eq TransElastosType::isCarType($callerRealDataType)) {
						my $carFileName = $callerRealDataType.".car";
						if (0 eq FileAnalysisCar::obtSpecifyCarName($carFileName)) {
							$carFileName = "I".$callerRealDataType;
							if (0 eq FileAnalysisCar::obtSpecifyCarName($carFileName)) {
								print __LINE__." doAnalysisEachFuncCall: can not find car $carFileName\n";
								<STDIN>;
							}
						}

						my $carName = "I".$callerRealDataType;
						my $ucFuncName = ucfirst($funcName);

						my @parmsContent = split(/,/, $funcParmsContent);
						my $parmCnt = @parmsContent;

						my $funcNode = FileAnalysisCar::obtSpecifyFuncInCurrCar($ucFuncName, $parmCnt);
						my $params = $funcNode->{ $FileTag::K_Params };
						my $outputParm = $params->[@$params - 1];
						my $outputParamType = $outputParm->{ $FileTag::K_ParamType };
						$outputParamType =~ s/\**$//;
						if (1 eq TransElastosType::isCarType($outputParamType)) {
							my $var = lcfirst($callerRealDataType);
							push @$funcCallContentTransed, @paramsExteneralExpress;
							push @$funcCallContentTransed, "AutoPtr<$carName> $var;\n";
							push @$funcCallContentTransed, "$caller->$ucFuncName($paramsTransedStr, ($carName**)&$var);\n";
							ScopeStackManager::stackPushVar($var, "AutoPtr<$carName>");
							$return = $outputParamType;
							if ($return !~ m/^I/) {
								$return = $var;
								$returnDataType = "I".$outputParamType;
							}
						}
						elsif (1 eq TransElastosType::isArrayOf($outputParamType)) {
							my $var = lcfirst($callerRealDataType);
							my $leftSharpBrackIdx = index($outputParamType, "<");
							my $rightSharpBrackIdx = rindex($outputParamType, ">");
							my $innerArrayOf = substr($outputParamType, $leftSharpBrackIdx+1, $rightSharpBrackIdx-$leftSharpBrackIdx-1);
							my $transInnerArrayOf = "";
							if ($innerArrayOf =~ m/\*$/) {
								$innerArrayOf =~ s/\**$//;
								$transInnerArrayOf = "AutoPtr<".$innerArrayOf.">";
								push @$funcCallContentTransed, @paramsExteneralExpress;
								push @$funcCallContentTransed, "AutoPtr< $transInnerArrayOf > $var;\n";
								ScopeStackManager::stackPushVar($var, "AutoPtr< $transInnerArrayOf >");
							}
							else {
								$transInnerArrayOf = $innerArrayOf;
								push @$funcCallContentTransed, @paramsExteneralExpress;
								push @$funcCallContentTransed, "AutoPtr<$transInnerArrayOf> $var;\n";
								ScopeStackManager::stackPushVar($var, "AutoPtr<$transInnerArrayOf>");
							}
							push @$funcCallContentTransed, "$caller->$ucFuncName($paramsTransedStr, &$var);\n";
							if ($return !~ m/^I/) {
								$return = $var;
								$returnDataType = "ArrayOf";
							}
						}
						else {
							my $var = $funcName;
							$var =~ s/^get//;
							$var = lcfirst($var);
							push @$funcCallContentTransed, @paramsExteneralExpress;
							push @$funcCallContentTransed, "$outputParamType $var;\n";
							push @$funcCallContentTransed, "$caller->$ucFuncName($paramsTransedStr, &$var);\n";
							ScopeStackManager::stackPushVar($var, "$outputParamType");
							if ($return !~ m/^I/) {
								$return = $var;
								$returnDataType = "$outputParamType";
							}
						}
					}
					elsif (1 eq TransElastosType::isArrayOf($callerRealDataType)) {
						push @$funcCallContentTransed, @paramsExteneralExpress;
						push @$funcCallContentTransed, "$ucFuncName($paramsTransedStr);\n";
					}
					else {
						print __LINE__." common var call getFunc, is it will exists?\n";
						<STDIN>;
					}
				}
				elsif ("CLASS" eq $callerLogicType) {
					push @$funcCallContentTransed, @paramsExteneralExpress;
					push @$funcCallContentTransed, "$ucFuncName($paramsTransedStr);\n";
				}
			}
			else {
				# is getCar: such like getContext((Int32)a)
				# to:
				# AutoPtr<IContext> context;
				# GetContext(a, (IContext**)&context);
				my $getWhat = $funcName;
				$getWhat =~ s/^get//;
				if (1 eq TransElastosType::isCarType($getWhat)) {
					my $var = lcfirst($getWhat);
					push @$funcCallContentTransed, @paramsExteneralExpress;
					push @$funcCallContentTransed, "AutoPtr<I$getWhat> $var;\n";
					push @$funcCallContentTransed, "$ucFuncName($paramsTransedStr, (I$getWhat**)&$var);\n";
					ScopeStackManager::stackPushVar($var, "AutoPtr<I$getWhat>");
				}
				else {
					push @$funcCallContentTransed, @paramsExteneralExpress;
					push @$funcCallContentTransed, "$ucFuncName($paramsTransedStr);\n";
				}
			}
		}
		# else func, ucfirst
		else {
			push @$funcCallContentTransed, @paramsExteneralExpress;
			push @$funcCallContentTransed, "$ucFuncName($paramsTransedStr);";
		}
	}

	return ($return, $returnDataType);
}

# input: just like "FuncName(***)"
sub doAnalysisWhole_SubEachFuncCallParms
{
	my $machSub = shift;
	my $parNode = shift;
	my $extenalExpress = shift;
	my $paramsTransed = shift;

	# func parms in func call will be real parm that must may be split by ','
	my @parms = split(/,/, $machSub);
	foreach my $item (@parms) {
		$item = Util::stringTrim($item);
		# single is donot need translate
		if ($item =~ m/^(\w+)$/) {
			# null is a multiple means,
			# if is a pointer, translate it to NULL
			# if is a String, translate it to ""
			# but is need more info so translate it as NULL temporary
			if ($item eq "null") {
				push @$paramsTransed, "NULL";
			}
			else {
				push @$paramsTransed, $item;
			}
		}
		# only call func once
		elsif ($item =~ m/^(\w+)\(/ && $item !~ m/^(\w+)\(.*?\)\./) {
			my $ucFunc = $1;
			$ucFunc = ucfirst($1);
			$item =~ s/^\w+/$ucFunc/;
			push @$paramsTransed, $item;
		}
		# only call func once
		elsif ($item =~ m/^(\w+)\.\(.*?\)/ && $item !~ m/^(\w+)\.\(.*?\)\./) {
			my $ucFunc = $1;
			$ucFunc = ucfirst($1);
			$item =~ s/^\w+/$ucFunc/;
			push @$paramsTransed, $item;
		}
		# var.var, or maybe more as: var.var.var
		elsif ($item =~ m/^(\w+)\.\w+/ && $item !~ m/^(\w+)\.\w+\(/) {
			my $firstWord = $1;
			if (1 eq TransElastosType::isCarType($firstWord)) {
				my @subs = split(/\./, $item);
				my $firstItem = $subs[0];
				$firstItem = "I".$firstItem;
				$subs[0] = $firstItem;
				my $tmp = join "::", @subs;
				push @$paramsTransed, $tmp;
			}
			# is not car but first letter is upper, may be a class
			elsif (1 eq Util::isStrFirstUpper($firstWord)) {
				my @subs = split(/\./, $item);
				my $tmp = join "::", @subs;
				push @$paramsTransed, $tmp;
			}
			# is not car and first letter isnot upper too, may be a var
			elsif (0 eq Util::isStrFirstUpper($firstWord)) {
				my ($find, $varType) = ScopeStackManager::findVarType($firstWord);
				if (1 eq TransElastosType::isAutoPtr($varType) || 1 eq TransElastosType::isPointer($varType)) {
					my @subs = split(/\./, $item);
					my $tmp = join "->", @subs;
					push @$paramsTransed, $tmp;
				}
				else {
					push @$paramsTransed, $item;
				}
			}
		}
		else {
			push @$paramsTransed, $item;
		}
	}
}

sub doAnalysisAssignRightFuncCall
{
	my $machSub = shift;
	my $parNode = shift;
	my $assignLeftNode = shift;
	my $funcCallContentTransed = shift;
	$machSub = Util::stringTrim($machSub);
	my $remainContent = $machSub;

	# remove like "(Int32)" force conversion
	if ($remainContent =~ m/^\(\w+\)/) {
		$remainContent =~ s/^\(\w+\)//;
	}

	my $currCaller = "";
	my $callerDataType = "";
	my $callerLogicType = "";
	if ($remainContent =~ m/^(\w+)\.\w+\(/) {
		$currCaller = $1;
		$remainContent =~ s/^\w+\.//;
		if (1 eq Util::isStrFirstUpper($currCaller)) {
			$callerLogicType = "CLASS";
			$callerDataType = $currCaller;
		}
		else {
			$callerLogicType = "VAR";
			# find var in var stack
			my ($find, $type) = ScopeStackManager::findVarType($currCaller);
			if ("" ne $type) {
				$callerDataType = $type;
			}
			else {
				print __LINE__." doAnalysisFuncCall: $currCaller may be a var but cannot find its type\n";
				<STDIN>;
				return;
			}
		}
	}
	# curr start of: "FuncName("
	my $isEndFunc = 0;
	while ("" ne $remainContent) {
		if ($remainContent =~ m/^\./) { $remainContent =~ s/^\.//; }
		last if (";" eq $remainContent);

		my $leftBracketsIdx = index($remainContent, "(");
		my ($isFind, $aimIdx) = Util::findBracketsEnd($remainContent, 0, "->", 0);
		last if (!($leftBracketsIdx >= 0 && 1 eq $isFind && $aimIdx > 0));

		my $eachFunc = substr($remainContent, 0, $aimIdx+1);
		$eachFunc = Util::stringTrim($eachFunc);

		$remainContent = substr($remainContent, $aimIdx+1);
		$remainContent = Util::stringTrim($remainContent);
		if ($remainContent =~ m/\./) { $isEndFunc = 0; }
		else { $isEndFunc = 1; }

		my @funcCallContentTransed = ();
		my $hasCaller = 0;
		if ("" ne $currCaller) { $hasCaller = 1; }

		my $testCurrFuncName = "";
		if ($eachFunc =~ m/^(\w+)/) { $testCurrFuncName = $1; }
		print __LINE__." \$eachFunc=[$eachFunc]\n";
		print __LINE__." CurrFunc: [$testCurrFuncName], caller=[$currCaller], callerDataType=[$callerDataType], callerLogicType=[$callerLogicType], \$isEndFunc=$isEndFunc\n";
		my ($return, $returnDataType) = &doAnalysisAssignRightSubEachFuncCall($eachFunc, $parNode, $assignLeftNode, $isEndFunc, \@funcCallContentTransed, $hasCaller, $currCaller, $callerDataType, $callerLogicType);
		if ("" ne $return) {
			$currCaller = $return;
			$callerDataType = $returnDataType;
			$callerLogicType = "VAR";
		}
		push @$funcCallContentTransed, @funcCallContentTransed;
	}
}

# input: just like "FuncName(***)"
sub doAnalysisAssignRightSubEachFuncCall
{
	my $machSub = shift;
	my $parNode = shift;
	my $assignLeftNode = shift;
	my $isEndFunc = shift;
	my $contentsTransed = shift;
	my $hasCaller = shift;
	my $caller = shift;
	my $callerDataType = shift; # such as "IContext", "AutoPtr<ILoadUrl>"
	my $callerLogicType = shift; # "", "VAR", "CLASS"(static)

	my ($return, $returnDataType);
	$return = "";
	$returnDataType = "";

	my $leftVarType = "";
	my $leftVarName = "";
	my $leftVarTypeTransed = "";
	if (1 eq $isEndFunc) {
		$leftVarType = $assignLeftNode->{ $FileTag::K_VarType };
		$leftVarName = $assignLeftNode->{ $FileTag::K_VarName };
		$leftVarTypeTransed = TransElastosType::transComplexVarDefineElastosType($leftVarType, 1);

		print __LINE__." R_EachFuncCall: \$leftVarTypeTransed=$leftVarTypeTransed, \$leftVarName=$leftVarName\n";
	}

	if ($machSub =~ m/^(\w+)\s*\(/) {
		my $funcName = $1;
		my $ucFuncName = ucfirst($funcName);

		my $leftBrackIdx = index($machSub, "(");
		my ($isFind, $aimIdx) = Util::findBracketsEnd($machSub, 0, "->", $leftBrackIdx);
		my $funcParmsContent = "";
		my @paramsExteneralExpress = ();
		my @paramsTransed = ();
		my $paramsTransedStr = "";
		if (1 eq $isFind) {
			$funcParmsContent = substr($machSub, $leftBrackIdx+1, $aimIdx - $leftBrackIdx - 1);
			$funcParmsContent = Util::stringTrim($funcParmsContent);
			if ("" ne $funcParmsContent) {
				&doAnalysisAssignRightSubEachFuncCallParms($funcParmsContent, $parNode, \@paramsExteneralExpress, \@paramsTransed);
				$paramsTransedStr = join ", ", @paramsTransed;
			}
		}
		else {
			print __LINE__." doAnalysisFuncCall: else\n";
			<STDIN>;
		}

		# func name start with get***
		# getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		#if ($funcName =~ m/^get/) {
			if (1 eq $hasCaller) {
				if ("VAR" eq $callerLogicType) {
					my $callerRealDataType = &obtRealDataType($callerDataType);
					$callerRealDataType =~ s/^I//;

					# AutoPtr is just a shell that donot be needed, remove out first.
					if (1 eq TransElastosType::isAutoPtr($callerRealDataType)) {
						$callerRealDataType =~ s/^AutoPtr<//;
						$callerRealDataType =~ s/>$//;
						$callerRealDataType = Util::stringTrim($callerRealDataType);
					}

					if (1 eq TransElastosType::isCarType($callerRealDataType)) {
						my $carFileName = $callerRealDataType.".car";
						#print __LINE__." analysis immediately\n";
						#<STDIN>;
						my ($analyCarOk, $realCarName) = FileAnalysisCar::obtFuzzyCarName($carFileName);
						if (0 eq $analyCarOk) {
							die "can not find fuzzy $realCarName, die\n";;
						}

						my $carName = "I".$callerRealDataType;
						my $ucFuncName = ucfirst($funcName);

						my @parmsContent = split(/,/, $funcParmsContent);
						my $parmCnt = @parmsContent;

						my ($find, $funcNode) = FileAnalysisCar::obtSpecifyFuncInCurrCar($ucFuncName, $parmCnt);
						if (0 eq $find) {
							die "can not find func $ucFuncName, die\n";;
						}

						my $params = $funcNode->{ $FileTag::K_Params };
						my $outputParm = $params->[@$params - 1];
						my $outputParamType = $outputParm->{ $FileTag::K_ParamType };
						print __LINE__." \$outputParamType=$outputParamType\n";

						# parm type end with "**" it may be Car type
						if ($outputParamType =~ m/\*{2,}$/) {
							# but this car type may cannot find ind cur java import express;
							# such as IInterface** similar base type
							# if it is the end func, use out parm type in func output
							# but return type use the left var type
							$outputParamType =~ s/\**$//;

							if (1 eq $isEndFunc) {
								#print __LINE__." is end func\n";
								if ("" eq $leftVarTypeTransed) {
									if ("" eq $paramsTransedStr) {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$caller->$ucFuncName(($outputParamType**)&$leftVarName);";
									}
									else {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, ($outputParamType**)&$leftVarName);";
									}
								}
								else {
									if ("" eq $paramsTransedStr) {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$leftVarTypeTransed $leftVarName;";
										push @$contentsTransed, "$caller->$ucFuncName(($outputParamType**)&$leftVarName);";
									}
									else {
										push @$contentsTransed, @paramsExteneralExpress;
										push @$contentsTransed, "$leftVarTypeTransed $leftVarName;";
										push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, ($outputParamType**)&$leftVarName);";
									}
								}
								$return = $leftVarName;
								if ($return !~ m/^I/) {
									$return = $leftVarName;
									$returnDataType = $leftVarTypeTransed;
								}
							}
							else {
								my $var = lcfirst($callerRealDataType);
								push @$contentsTransed, @paramsExteneralExpress;
								push @$contentsTransed, "AutoPtr<$carName> $var;\n";
								if ("" eq $paramsTransedStr) {
									push @$contentsTransed, "$caller->$ucFuncName(($carName**)&$var);";
								}
								else {
									push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, ($carName**)&$var);";
								}

								$return = $outputParamType;
								if ($return !~ m/^I/) {
									$return = $var;
									$returnDataType = "I".$outputParamType;
								}
							}
						}
						elsif (1 eq TransElastosType::isArrayOf($outputParamType)) {
							my $var = lcfirst($callerRealDataType);
							my $leftSharpBrackIdx = index($outputParamType, "<");
							my $rightSharpBrackIdx = rindex($outputParamType, ">");
							my $innerArrayOf = substr($outputParamType, $leftSharpBrackIdx+1, $rightSharpBrackIdx-$leftSharpBrackIdx-1);
							my $transInnerArrayOf = "";
							if ($innerArrayOf =~ m/\*$/) {
								$innerArrayOf =~ s/\**$//;
								$transInnerArrayOf = "AutoPtr<".$innerArrayOf.">";
								push @$contentsTransed, @paramsExteneralExpress;
								push @$contentsTransed, "AutoPtr< $transInnerArrayOf > $var;";
							}
							else {
								$transInnerArrayOf = $innerArrayOf;
								push @$contentsTransed, @paramsExteneralExpress;
								push @$contentsTransed, "AutoPtr<$transInnerArrayOf> $var;";
							}

							if ("" eq $paramsTransedStr) {
								push @$contentsTransed, "$caller->$ucFuncName(&$var);";
							}
							else {
								push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, &$var);";
							}

							if ($return !~ m/^I/) {
								$return = $var;
								$returnDataType = "ArrayOf";
							}
						}
						else {
							my $var = $funcName;
							$var =~ s/^get//;
							$var = lcfirst($var);
							push @$contentsTransed, @paramsExteneralExpress;
							push @$contentsTransed, "$outputParamType $var;";

							if ("" eq $paramsTransedStr) {
								push @$contentsTransed, "$caller->$ucFuncName(&$var);";
							}
							else {
								push @$contentsTransed, "$caller->$ucFuncName($paramsTransedStr, &$var);";
							}

							if ($return !~ m/^I/) {
								$return = $var;
								$returnDataType = "$outputParamType";
							}
						}
					}
					elsif (1 eq TransElastosType::isArrayOf($callerRealDataType)) {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
					}
					else {
						print __LINE__." common var call getFunc, is it will exists?\n";
						<STDIN>;
					}
				}
				elsif ("CLASS" eq $callerLogicType) {
					push @$contentsTransed, @paramsExteneralExpress;
					push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
				}
			}
			# no caller
			else {
				# is getCar: such like getContext((Int32)a)
				# to:
				# AutoPtr<IContext> context;
				# GetContext(a, (IContext**)&context);
				my $getWhat = $funcName;
				$getWhat =~ s/^get//;
				if (1 eq $isEndFunc) {
					my $var = lcfirst($getWhat);
					if (1 eq TransElastosType::isCarType($getWhat) || 1 eq TransElastosType::isCarType($leftVarTypeTransed)) {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "AutoPtr<$leftVarTypeTransed> $var;";

						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$ucFuncName(($leftVarTypeTransed**)&$var);";
						}
						else {
							push @$contentsTransed, "$ucFuncName($paramsTransedStr, ($leftVarTypeTransed**)&$var);";
						}
					}
					else {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "$leftVarTypeTransed $var;";
						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$ucFuncName(&$var);";
						}
						else {
							push @$contentsTransed, "$ucFuncName($paramsTransedStr, &$var);";
						}
					}
				}
				# func isnot end
				else {
					# first need search func in curr class
					&obtCurrFuncOutFuncDefineInCurrMainClassAndSaveTmp($parNode);
					my $mayRet = "";
					if (1 eq &findFuncDefineInObtOutFuncsDefineInTmp($ucFuncName, \$mayRet)) {
						my $retTransed = TransElastosType::transComplexReturnElastosType($mayRet, 1);
						my $var = lcfirst($getWhat);
						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$retTransed $var = $ucFuncName();";
						}
						else {
							push @$contentsTransed, "$retTransed $var = $ucFuncName($paramsTransedStr);";
						}
						$return = $var;
						$returnDataType = $retTransed;
					}
					elsif (1 eq TransElastosType::isCarType($getWhat)) {
						my $var = lcfirst($getWhat);
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "AutoPtr<I$getWhat> $var;";
						if ("" eq $paramsTransedStr) {
							push @$contentsTransed, "$ucFuncName((I$getWhat**)&$var);";
						}
						else {
							push @$contentsTransed, "$ucFuncName($paramsTransedStr, (I$getWhat**)&$var);";
						}
						$return = $var;
						$returnDataType = $getWhat;
					}

					else {
						push @$contentsTransed, @paramsExteneralExpress;
						push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
					}
				}
			}
		#}
=pod
		# else func, ucfirst
		else {
			if (1 eq $isEndFunc) {
				my $express = "";
				if ("" eq $leftVarTypeTransed) {
					$express = "$leftVarName = $ucFuncName($paramsTransedStr);";
				}
				else {
					$express = "$leftVarTypeTransed $leftVarName = $ucFuncName($paramsTransedStr);";
				}

				push @$contentsTransed, @paramsExteneralExpress;
				push @$contentsTransed, $express;
			}
			else {
				push @$contentsTransed, @paramsExteneralExpress;
				push @$contentsTransed, "$ucFuncName($paramsTransedStr);";
			}

		}
=cut

	}

	return ($return, $returnDataType);
}

# input: just like "FuncName(***)"
sub doAnalysisAssignRightSubEachFuncCallParms
{
	my $machSub = shift;
	my $parNode = shift;
	my $extenalExpress = shift;
	my $paramsTransed = shift;

	# func parms in func call will be real parm that must may be split by ','
	my @parms = split(/,/, $machSub);
	foreach my $item (@parms) {
		$item = Util::stringTrim($item);
		# single is donot need translate
		if ($item =~ m/^(\w+)$/) {
			# null is a multiple means,
			# if is a pointer, translate it to NULL
			# if is a String, translate it to ""
			# but is need more info so translate it as NULL temporary
			if ($item eq "null") {
				push @$paramsTransed, "NULL";
			}
			else {
				push @$paramsTransed, $item;
			}
		}
		# only call func once
		elsif ($item =~ m/^(\w+)\(/ && $item !~ m/^(\w+)\(.*?\)\./) {
			my $ucFunc = $1;
			$ucFunc = ucfirst($1);
			$item =~ s/^\w+/$ucFunc/;
			push @$paramsTransed, $item;
		}
		# only call func once
		elsif ($item =~ m/^(\w+)\.\(.*?\)/ && $item !~ m/^(\w+)\.\(.*?\)\./) {
			my $ucFunc = $1;
			$ucFunc = ucfirst($1);
			$item =~ s/^\w+/$ucFunc/;
			push @$paramsTransed, $item;
		}
		# var.var, or maybe more as: var.var.var
		elsif ($item =~ m/^(\w+)\.\w+/ && $item !~ m/^(\w+)\.\w+\(/) {
			my $firstWord = $1;
			if (1 eq TransElastosType::isCarType($firstWord)) {
				my @subs = split(/\./, $item);
				my $firstItem = $subs[0];
				$firstItem = "I".$firstItem;
				$subs[0] = $firstItem;
				my $tmp = join "::", @subs;
				push @$paramsTransed, $tmp;
			}
			# is not car but first letter is upper, may be a class
			elsif (1 eq Util::isStrFirstUpper($firstWord)) {
				my @subs = split(/\./, $item);
				my $tmp = join "::", @subs;
				push @$paramsTransed, $tmp;
			}
			# is not car and first letter isnot upper too, may be a var
			elsif (1 eq Util::isStrFirstUpper($firstWord)) {
				my ($find, $varType) = ScopeStackManager::findVarType($firstWord);
				if (1 eq TransElastosType::isAutoPtr($varType) || 1 eq TransElastosType::isPointer($varType)) {
					my @subs = split(/\./, $item);
					my $tmp = join "->", @subs;
					push @$paramsTransed, $tmp;
				}
				else {
					push @$paramsTransed, $item;
				}
			}
		}
		else {
			push @$paramsTransed, $item;
		}
	}
}

my $gOutofFuncsDefines;
sub obtCurrFuncOutFuncDefineInCurrMainClassAndSaveTmp
{
	my $funcNode = shift;
	my @funcDefines = ();

	if (exists ($funcNode->{ $FileTag::K_NodeName }) && exists ($funcNode->{ $FileTag::K_Return })) {
		my $funcName = $funcNode->{ $FileTag::K_NodeName };
		my $funcRet = $funcNode->{ $FileTag::K_Return };
		my %funcInfo = ();
		$funcInfo{ $funcName } = $funcRet;
		push @funcDefines, \%funcInfo;
	}

	if (exists ($funcNode->{ $FileTag::K_ParNode })) {
		my $parNode = $funcNode->{ $FileTag::K_ParNode };
		my $parType = $parNode->{ $FileTag::K_NodeType };
		while ("DOC" ne $parType) {
			if (exists ($parNode->{ $FileTag::K_SubNodes })) {
				my $subNodes = 	$parNode->{ $FileTag::K_SubNodes };
				foreach my $child (@$subNodes) {
					if (exists ($child->{ $FileTag::K_NodeType })) {
						my $childType = $child->{ $FileTag::K_NodeType };
						if ("FUNC" eq $childType) {
							my $funcName = $child->{ $FileTag::K_NodeName };
							my $funcRet = $child->{ $FileTag::K_Return };
							my %funcInfo = ();
							$funcInfo{ $funcName } = $funcRet;
							push @funcDefines, \%funcInfo;
						}
					}
				}
			}
			$parNode = $parNode->{ $FileTag::K_ParNode };
			$parType = $parNode->{ $FileTag::K_NodeType };
		}
	}

	$gOutofFuncsDefines = \@funcDefines;
	return \@funcDefines;
}

sub findFuncDefineInObtOutFuncsDefineInTmp
{
	my $funcName = shift;
	my $funcRet = shift; # reference
	$funcName = ucfirst($funcName);
	if (!defined($gOutofFuncsDefines)) { return 0; }
	my @funcNames = keys @$gOutofFuncsDefines;
	foreach (@funcNames) {
		if ($_ eq $funcName) {
			$$funcRet = $gOutofFuncsDefines->{ $funcName };
			return 1;
		}
	}
	return 0;
}

sub findFuncParamType
{
	my $parNode = shift;
	my $callerName = shift;
	my $funcName = shift;
	my $paramsCnt = shift;
	my $paramsIdx = shift;
	my ($parmFind, $parmType);
	$parmFind = 0;
	$parmType = "";

	my ($find, $funcPosType, $funcReturn, $params) = &findFuncDefineAnywhere($parNode, $callerName, $funcName, $paramsCnt);
	if (1 eq $find)	 {
		if ($paramsIdx < 0) { $paramsIdx = 0; }
		if ($paramsIdx >= @$params) { return ($parmFind, $parmType); }
		my $machParam = $params[$paramsIdx];
		$parmFind = 1;
		$parmType = $machParam->{ $FileTag::K_ParamType };
		return ($parmFind, $parmType);
	}
	return ($parmFind, $parmType);
}

sub findFuncReturnType
{
	my $parNode = shift;
	my $callerName = shift;
	my $funcName = shift;
	my $paramsCnt = shift;
	my ($retFind, $retType);
	$retFind = 0;
	$retType = "";

	my ($find, $funcPosType, $funcReturn, $params) = &findFuncDefineAnywhere($parNode, $callerName, $funcName, $paramsCnt);
	if (1 eq $find)	 {
		$retFind = 1;
		$retType = $funcReturn;
		return ($retFind, $retType);
	}
	return ($retFind, $retType);
}

sub findFuncDefineAnywhere
{
	my $parNode = shift;
	my $callerName = shift;
	my $funcName = shift;
	my $paramsCnt = shift;  # simple check the count of params

	$callerName = Util::stringTrim($callerName);
	$funcName = ucfirst($funcName);

	my ($find, $funcPosType, $funcReturn, $params);
	$find = 0;
	$funcPosType = "";
	$funcReturn = "";

	# if has no caller, it will be one of current class
	if ("" eq $callerName) {
		# first check caller whether is in curr java file
		my ($funcFind, $funcNode) = $parNode->getFuncInMainClass($type, $funcName, $paramsCnt);
		if (1 eq $funcFind) {
			$find = 1;
			$funcPosType = "CURR_JAVA";
			$funcReturn = $funcNode->{ $FileTag::K_Return };
			$params = $funcNode->{ $FileTag::K_Params };
			return ($find, $funcPosType, $funcReturn, $params);
		}
	}

	# check caller's type
	my ($find, $type) = ScopeStackManager::findVarType($callerName);
	if (0 eq $find) {
		return ($find, $funcPosType, $funcReturn, $params);
	}
	$type = Util::rmSignLikeAutoPtr($type, "AutoPtr");

	if (1 eq TransElastosType::isCommonType($type)) {
		return ($find, $funcPosType, $funcReturn, $params);
	}

	# check whether is a car, this
	my $typeTmp = $type;
	$typeTmp =~ s/^I//;
	if (1 eq TransElastosType::isCarType($typeTmp)) {
		my $mayCarName = $typeTmp.".car";
		my ($analysisOk, $realCarName) = FileAnalysisCar::obtFuzzyCarName($mayCarName);
		if (0 eq $analysisOk) {
			return ($find, $funcPosType, $funcReturn, $params);
		}

		my $carName = "I".$typeTmp;
		my ($find, $funcNode) = FileAnalysisCar::obtSpecifyFuncInCurrCar($funcName, $paramsCnt);
		if (0 eq $find) {
			return ($find, $funcPosType, $funcReturn, $params);
		}

		$find = 1;
		$funcPosType = "CAR";
		$funcReturn = "";
		$params = $funcNode->{ $FileTag::K_Params };
		return ($find, $funcPosType, $funcReturn, $params);
	}

	# first check caller whether is in curr java file
	my ($funcFind, $funcNode) = $parNode->getFuncInMainClass($type, $funcName, $paramsCnt);
	if (1 eq $funcFind) {
		$find = 1;
		$funcPosType = "CURR_JAVA";
		$funcReturn = $funcNode->{ $FileTag::K_Return };
		$params = $funcNode->{ $FileTag::K_Params };
		return ($find, $funcPosType, $funcReturn, $params);
	}

	# caller is in other java file, check the other java files that is same layer with current java file
	my $javaPathsSameLayer = FileOperate::getFilePathsByFileSameLayer($parNode->getJavaPath, ".java");
	foreach my $path (@$javaPathsSameLayer) {
		my $fileNameNoEndPrefix = Util::getFileNameNoEndPrefixByPath($path);
		if ($type eq $fileNameNoEndPrefix) {
			my $otherJavaDoc = FileAnalysisJavaNoFunc::analysisFile($path, 0);
			my ($funcFind, $funcNode) = $otherJavaDoc->getFuncInMainClass($type, $funcName, $paramsCnt);
			if (1 eq $funcFind) {
				$find = 1;
				$funcPosType = "OTHER_JAVA";
				$funcReturn = $funcNode->{ $FileTag::K_Return };
				$params = $funcNode->{ $FileTag::K_Params };
				return ($find, $funcPosType, $funcReturn, $params);
			}
		}
	}

	return ($find, $funcPosType, $funcReturn, $params);
}

sub getDataTypeFromCallerName
{
	my $callerName = shift;
	my ($varFind, $varType) = ScopeStackManager::findVarType($callerName);
	return ($varFind, $varType);
}

sub getLogicTypeFromCallerName
{
	my $callerName = shift;
	my ($varFind, $varType);
	$varFind = 0;
	$varType = "";
	if ("" eq $callerName) { return ($varFind, $varType); }
	if (1 eq Util::isStrFirstUpper($callerName)) {
		$varFind = 1;
		$varType = "CLASS";
		return ($varFind, $varType);
	}
	else {
		varFind = 1;
		$varType = "VAR";
		return ($varFind, $varType);
	}
}

sub obtRealDataType
{
	my $type = shift;
	if ($type =~ m/^AutoPtr</) {
		$type =~ s/^AutoPtr<//;
		return &obtRealDataType($type);
	}
	elsif ($type =~ m/^(\w+)</) {
		return $1;
	}
	elsif ($type =~ m/^(\w+)/) {
		return $1;
	}
	else {
		return $type;
	}
}

sub obtFuncCallParamContent
{
	my $eachFuncCall = shift;
	my ($find, @params);
	$find = 0;
	@params = ();

	my $leftBrackIdx = index($eachFuncCall, "(");
	my $rightBrackIdx = rindex($eachFuncCall, ")");
	if ($leftBrackIdx < 0 || $rightBrackIdx < 0 || $leftBrackIdx >= $rightBrackIdx) {
		return ($find, \@params);
	}
	my $funcParamsContent = substr($eachFuncCall, $leftBrackIdx+1, $rightBrackIdx-$leftBrackIdx-1);
	$funcParamsContent = Util::stringTrim($funcParamsContent);
	if ("" eq $funcParamsContent) {
		return ($find, \@params);
	}
	\@params = Util::stringSplitParamsContent($funcParamsContent);
	return ($find, @params);
}

sub fmtSelfData
{
	my $machSub = shift;
	my $startSpace = shift;

	my @funcContextLines = split(/\n/, $machSub);
	my $funcContext = Util::stringArrayFormatLine(\@funcContextLines, $startSpace);
   	my $funcContextLine = join "\n", @$funcContext;
	if ("" ne $funcContextLine) {
		return $startSpace."/*$funcContextLine*/\n";
	}
	return "";
}

sub fmtSelfTransedData
{
	my $machSub = shift;
	my $startSpace = shift;

	my @funcContextLines = split(/\n/, $machSub);
	my $funcContext = Util::stringArrayFormatLine(\@funcContextLines, $startSpace);
   	my $funcContextLine = join "\n", @$funcContext;
   	$funcContextLine = $funcContextLine;
	return $funcContextLine;
}


1;

