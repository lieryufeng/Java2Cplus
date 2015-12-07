#!/usr/bin/perl;

package FileAnalysisJavaPolishC_while;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( polishAnalisisStruct, polishRoot );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;
use TransElastosType;

my $TAB = "    ";
my $gCurrDotHRoot;

# insert using namespace pointer
my $gUsingNamespace;
my $gUsingNamespaceParentNode;
my $gUsingNamespaceAfterNode;
my @gInsertUsingNamespace = ();

sub clear
{
	$gUsingNamespace = 0;
	@gInsertUsingNamespace = ();
}

sub polishAnalisisStruct
{
	my $dotHRoot = shift;
	my $dotCppRoot = shift;
	my $filePath = $dotHRoot->{ $FileTag::K_NodeName };
	my $dotHPath = $filePath;
	$dotHPath =~ s/\.java/\.h/g;
	my $dotCppPath = $filePath;
	$dotCppPath =~ s/\.java/\.cpp/g;
	&clear;
	my ($dotHContext, $dotCppContext) = &polishRoot($dotHRoot, $dotCppRoot);
}

sub polishRoot
{
	my $dotHRoot = shift;
	my $dotCppRoot = shift;
	$gCurrDotHRoot = $dotHRoot;
	my @dotHContexts = ();
	my @dotCppContexts = ();

	my $startSpace = "";
	# .h
	{
		my $childs = $dotHRoot->{ $FileTag::K_SubNodes };
		foreach (@$childs) {
			&polishContext($_, \@dotHContexts, 0, $startSpace);
		}
	}
	# .cpp
	{
		my $childs = $dotCppRoot->{ $FileTag::K_SubNodes };
		foreach (@$childs) {
			&polishContext($_, \@dotCppContexts, 1, $startSpace);
		}
	}

	return (\@dotHContexts, \@dotCppContexts);
}

sub polishContext
{
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	if (!exists ($item->{ $FileTag::K_NodeTag })) {
		return $dotContexts;
	}

	my $tag = $item->{ $FileTag::K_NodeTag };
	if (FileTag::isTagValid($tag)) {
		if ($FileTag::DC_empty eq $tag) {
    		&polishEmpty($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_package eq $tag) {
    		&polishPackage($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_import eq $tag) {
    		&polishImport($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_astart eq $tag) {
    		&polishAStart($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_note eq $tag) {
    		&polishNote($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_class eq $tag) {
    		&polishClass($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_interface eq $tag) {
    		&polishInterface($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
		elsif ($FileTag::DC_function_define eq $tag) {
    		&polishFuncDefine($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
		elsif ($FileTag::DC_function_call eq $tag) {
    		&polishFuncCall($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_if eq $tag) {
    		&polishLogicIf($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_elseif eq $tag) {
    		&polishLogicElseIf($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_else eq $tag) {
    		&polishLogicElse($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_switch eq $tag) {
    		&polishLogicSwitch($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_while eq $tag) {
    		&polishLogicWhile($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_for eq $tag) {
    		&polishLogicFor($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_var_define eq $tag) {
    		&polishVarDefine($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_var_assignment eq $tag) {
    		&polishVarAssignment($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	# insert by polish
    	elsif ($FileTag::DC_scope eq $tag) {
			&polishScope($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_namespace_start eq $tag) {
			&polishNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_namespace_end eq $tag) {
			&polishNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_macro_start eq $tag) {
			&polishMarco($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_macro_end eq $tag) {
			&polishMarco($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_class_note eq $tag) {
			&polishClassNote($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_include eq $tag) {
			&polishInclude($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_using_namespace eq $tag) {
			&polishUsingNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	else {
    		my $strTag = FileTag::getTagString($tag);
    		print __LINE__."[E] \$DC var match failed. \$strTag=$strTag\n";
    	}
	}

	return $dotContexts;
}


sub polishEmpty
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
}

sub polishPackage
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
}

sub polishImport
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
}

sub polishAStart
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
}

sub polishNote
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
}

sub polishClass
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

    my $className = $item->{ $FileTag::K_NodeName };
    my $parents = $item->{ $FileTag::K_Parents };

    #print __LINE__." polishClass: \$className=$className\n";

	if (0 eq $dotHCpp) {
		my @classDefine = ();
		if (1 eq polishBaseToObjectControl($item)) {
			if (0 == @$parents) {
			}
			elsif (1 == @$parents) {
				my $fmtParName = $parents->[0];
				#$fmtParName =~ s/\./::/g;
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
			}
			else {
				my $fmtParName = $parents->[0];
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				for (my $idx=1; $idx<@$parents; ++$idx) {
					$fmtParName = $parents->[$idx];
					#$fmtParName =~ s/\./::/g;
					$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				}
			}
		}
		else {
			if (0 == @$parents) {
			}
			elsif (1 == @$parents) {
				my $fmtParName = $parents->[0];
				#$fmtParName =~ s/\./::/g;
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
			}
			else {
				my $fmtParName = $parents->[0];
				#$fmtParName =~ s/\./::/g;
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				for (my $idx=1; $idx<@$parents; ++$idx) {
					$fmtParName = $parents->[$idx];
					#$fmtParName =~ s/\./::/g;
					$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				}
			}
		}

		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&polishContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}

		&polishReduceEmptyLine($dotContexts);
	}
	else {
		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&polishContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}
	}
}

sub polishInterface
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

    my $className = $item->{ $FileTag::K_NodeName };
    my $parents = $item->{ $FileTag::K_Parents };

	if (0 eq $dotHCpp) {
		my @classDefine;
		if (0 == @$parents) {
		}
		elsif (1 == @$parents) {
			my $fmtParName = $parents->[0];
			$fmtParName =~ s/\./::/g;
		}
		else {
			my $fmtParName = $parents->[0];
			$fmtParName =~ s/\./::/g;
			for (my $idx=1; $idx<@$parents; ++$idx) {
				$fmtParName = $parents->[$idx];
				$fmtParName =~ s/\./::/g;
			}
		}
		push @$dotContexts, @classDefine;
		push @$dotContexts, $startSpace."{\n";

		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&polishContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}

		&polishReduceEmptyLine($dotContexts);
	}
	else {
		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&polishContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}
	}
}

sub polishFuncDefine
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	my $scope = $item->{ $FileTag::K_Scope };
	my $funcRet = $item->{ $FileTag::K_Return };
	my $funcName = $item->{ $FileTag::K_NodeName };
   	my $isStatic = $item->{ $FileTag::K_Static };
   	my $isFinal = $item->{ $FileTag::K_Final };
   	my $isNative = $item->{ $FileTag::K_Native };
   	my $isVirtual = $item->{ $FileTag::K_Virtual };
   	my $isPureVirtual = $item->{ $FileTag::K_PureVirtual };
   	my $isSynchronized = $item->{ $FileTag::K_Synchronized };
   	my $isAbstract = $item->{ $FileTag::K_Abstract };
   	my $params = $item->{ $FileTag::K_Params };
   	my $initList = $item->{ $FileTag::K_InitList };
   	my $isCarFunc = $item->{ $FileTag::K_IsCarFunc };

   	if (!defined($isVirtual)) {
   	}

	# .h
	if (0 eq $dotHCpp) {
		my @tmps;
		my $tmp = "";
		$tmp = $tmp.$startSpace;
		if (1 eq $isSynchronized) {
		}

		$tmp = "";
		$tmp = $tmp.$startSpace;
		if (1 eq $isVirtual) { $tmp = $tmp."virtual "; }
		if (1 eq $isStatic) { $tmp = $tmp."static "; }
		if (1 eq $isFinal) { $tmp = $tmp."const "; }
		if ("" ne $funcRet) {
			if (1 eq $isCarFunc) {
			}
			elsif ("void" eq $funcRet && "public" ne $scope) {
			}
			else {
				my $dstType;
				if (1 eq ToolDealImports::isImportType($funcRet, \$dstType)) {
					my $using;
					ToolDealImports::obtUsingBySrcType($funcRet, \$using);
					print __LINE__." polishFuncDefine: \$using=$using\n";
					&tryInsertUsingNamespaceNode($using);
				}
			}
		}

		if (0 == @$params) {
			if (1 eq $isCarFunc && "" ne $funcRet && "void" ne $funcRet) {
				my $newFuncRet = TransElastosType::transOutParamElastosType($funcRet);

			}
			else {
			}
		}
		else {
			my $startSpaceTmp = $startSpace.$TAB;
			my $parmType;
			my $parmName;
			for (my $idx=0; $idx<@$params; ++$idx) {
				$parmType = $params->[$idx]->{ $FileTag::K_ParamType };
				$parmName = $params->[$idx]->{ $FileTag::K_ParamName };
				my $newParmType = TransElastosType::transComplexParamElastosType($parmType);

				my $dstType;
				if (1 eq ToolDealImports::isImportType($parmType, \$dstType)) {
					my $using;
					ToolDealImports::obtUsingBySrcType($parmType, \$using);
					print __LINE__." polishFuncDefine: \$using=$using\n";
					&tryInsertUsingNamespaceNode($using);
				}

				print __LINE__." transParam: $parmType => $newParmType\n";
				$tmp = $startSpaceTmp."/* [in] */ $newParmType $parmName";
				if ($idx eq @$params - 1) {
					# if is car func, need add out param here
					if (1 eq $isCarFunc && "" ne $funcRet && "void" ne $funcRet) {
						$tmp = $tmp.",\n";
						push @tmps, $tmp;

						my $newFuncRet = TransElastosType::transOutParamElastosType($funcRet);
						$tmp = $startSpaceTmp."/* [out] */ $newFuncRet result)";
					}
					else {
						$tmp = $tmp.")";
					}
				}
				else {
					$tmp = $tmp.",\n";
					push @tmps, $tmp;
				}
			}
		}

		if (1 eq $isPureVirtual || 1 eq $isAbstract) { $tmp = $tmp." = 0;\n"; }
		else { $tmp = $tmp.";\n"; }
		push @tmps, $tmp;
		push @tmps, "\n";
		push @$dotContexts, @tmps;
	}

	# .cpp
	if (1 eq $dotHCpp) {
		my @tmps;
		$startSpace = "";
		&polishEmptyLine($dotContexts);
		if (1 eq $isSynchronized) {
			my $tmp = "// synchronized\n";
			push @tmps, $tmp;
		}
		my $tmp = $startSpace;
		if (1 eq $isPureVirtual || 1 eq $isAbstract) { return; }
		if (1 eq $isFinal) { $tmp = $tmp."const "; }

		my $dotCppFuncRet = "";
		if ("" ne $funcRet) {
			# equal "public" and isnot override, it will be trans to CAR interface, so return is CARAPI,
			# and source return will trans to out param
			if (1 eq $isCarFunc) {
				$tmp = $tmp."ECode ";
				$dotCppFuncRet = "ECode";
			}
			elsif ("void" eq $funcRet && "public" ne $scope) {
				$tmp = $tmp."void ";
				$dotCppFuncRet = "void";
			}
			else {
				$dotCppFuncRet = TransElastosType::transComplexReturnElastosType($funcRet, 1);
				$tmp = $tmp."$dotCppFuncRet ";
			}
		}
		if ("" ne $funcName) {
			my $scopePath = $item->currScopePath;
			$tmp = $tmp."$scopePath"."::"."$funcName(";
		}

		my @needCheckPointer = ();
		if (0 == @$params) {
			if (1 eq $isCarFunc && "" ne $funcRet && "void" ne $funcRet) {
				$tmp = $tmp."\n";
				push @tmps, $tmp;

				my $newFuncRet = TransElastosType::transOutParamElastosType($funcRet);
				my $startSpaceTmp = $startSpace.$TAB;
				$tmp = $startSpaceTmp."/* [out] */ $newFuncRet result)\n";
				push @needCheckPointer, "result";
			}
			else {
				$tmp = $tmp.")\n";
			}
		}
		else {
			push @tmps, $tmp."\n";
			my $startSpaceTmp = $startSpace.$TAB;
			my $parmType;
			my $parmName;
			for (my $idx=0; $idx<@$params; ++$idx) {
				$parmType = $params->[$idx]->{ $FileTag::K_ParamType };
				$parmName = $params->[$idx]->{ $FileTag::K_ParamName };
				$parmType = TransElastosType::transComplexParamElastosType($parmType);
				if ("ECode" eq $dotCppFuncRet && $parmType =~ m/\*$/) {
					push @needCheckPointer, $parmName;
				}
				$tmp = $startSpaceTmp."/* [in] */ $parmType $parmName";
				if ($idx eq @$params - 1) {
					if (1 eq $isCarFunc && "" ne $funcRet && "void" ne $funcRet) {
						$tmp = $tmp.",\n";
						push @tmps, $tmp;

						my $newFuncRet = TransElastosType::transOutParamElastosType($funcRet, 1);
						$tmp = $startSpaceTmp."/* [out] */ $newFuncRet result";
						push @needCheckPointer, "result";
					}
					$tmp = $tmp.")\n";
				}
				else {
					$tmp = $tmp.",\n";
					push @tmps, $tmp;
				}
			}
		}

		push @tmps, $tmp;

		my $listFirst = 1;
		$startSpace = "    ";
		if ("" eq $funcRet) {
			foreach (@$initList) {
				if (1 eq $listFirst) { push @tmps, $startSpace.": $_\n"; }
				else { push @tmps, $startSpace.", $_\n"; }
			}
		}

		push @tmps, "{\n";
		$startSpace = $TAB;
		{
			foreach (@needCheckPointer) {
				push @tmps, $startSpace."VALIDATE_NOT_NULL($_);\n";
			}

			my $funcContext = "";
			if (exists ($item->{ $FileTag::K_InnerContext })) {
				$funcContext = $item->{ $FileTag::K_InnerContext };
				if ("" ne $funcContext) {
					my @funcContextLines = split(/\n/, $funcContext);
					my $fmtFuncContext = Util::stringArrayFormatLine(\@funcContextLines, "");
					$fmtFuncContext = Util::commitOutArray($fmtFuncContext);
					$fmtFuncContext = Util::stringArrayFormatLine($fmtFuncContext, $startSpace);
				   	my $funcContextLine = join "\n", @$fmtFuncContext;
					if ("" ne $funcContextLine) {
						push @tmps, $startSpace."// ==================before translated======================\n";
						push @tmps, "$funcContextLine\n";
					}
				}
			}

			if ("" ne $funcRet) {
				push @tmps, $startSpace."assert(0);\n";
			}

			if (exists ($item->{ $FileTag::K_InnerContextTransed })) {
				$funcContext = $item->{ $FileTag::K_InnerContextTransed };
				if ("" ne $funcContext) {
					my @funcContextLines = split(/\n/, $funcContext);
					$funcContext = Util::stringArrayFormatLine(\@funcContextLines, $startSpace);
				   	my $funcContextLine = join "\n", @$funcContext;
					if ("" ne $funcContext) {
						push @tmps, "\n";
						push @tmps, $startSpace."// ===================after translated======================\n";
						push @tmps, "$funcContextLine\n";
					}
				}
			}
			&polishReturn(\@tmps, $dotCppFuncRet, $startSpace);
		}
		push @tmps, "}\n";
		push @tmps, "\n";
		push @$dotContexts, @tmps;
	}
}

sub polishFuncCall
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub polishLogicIf
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub polishLogicElseIf
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub polishLogicElse
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub polishLogicSwitch
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub polishLogicWhile
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;


}

sub polishLogicFor
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub polishVarDefine
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	my $scope = $item->{ $FileTag::K_Scope };
   	my $isStatic = $item->{ $FileTag::K_Static };
   	my $isFinal = $item->{ $FileTag::K_Final };
   	my $varComplexType = $item->{ $FileTag::K_VarType };
   	my $varComplexName = $item->{ $FileTag::K_VarName };

	# .h
	if (0 eq $dotHCpp) {
		my $tmp = $startSpace;
		if (1 eq $isStatic) { $tmp = $tmp."static "; }
		if (1 eq $isFinal) {
			if (1 eq $isStatic) { $tmp = $tmp."const "; }
			else { $tmp = $tmp."/*const*/ "; }
		}
		my $newComplexType = TransElastosType::transComplexVarDefineElastosType($varComplexType, 0);
		$tmp = $tmp."$newComplexType $varComplexName;\n";
		push @$dotContexts, $tmp;
	}

	# .cpp
	if (1 eq $dotHCpp) {
		my $tmp = "";
		if (1 eq $isStatic) {
			if (1 eq $isFinal) { $tmp = $tmp."const "; }
			my $scopePath = $item->currScopePath;
			my $newComplexType = TransElastosType::transComplexVarDefineElastosType($varComplexType, 1);
			$tmp = $tmp."$newComplexType $scopePath"."::"."$varComplexName;\n";
			push @$dotContexts, $tmp;
		}
	}
}

sub polishVarAssignment
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	my $scope = $item->{ $FileTag::K_Scope };
	my $leftNode = $item->{ $FileTag::K_VarAssL };
	my $leftVarType = $leftNode->{ $FileTag::K_VarType };
	my $leftVarName = $leftNode->{ $FileTag::K_VarName };
	my $leftIsStatic = $leftNode->{ $FileTag::K_Static };
	my $leftIsFinal = $leftNode->{ $FileTag::K_Final };

	my $rightNode = $item->{ $FileTag::K_VarAssR };
   	my $rightData = $rightNode->{ $FileTag::K_SelfData };

	# .h
	if (0 eq $dotHCpp) {
		my $tmp = $startSpace;
		if (1 eq $leftIsStatic) { $tmp = $tmp."static "; }
		if (1 eq $leftIsFinal) {
			if (1 eq $leftIsStatic) { $tmp = $tmp."const "; }
			else { $tmp = $tmp."/*const*/ "; }
		}

		my $newComplexType = Util::stringTrim(TransElastosType::transComplexVarDefineElastosType($leftVarType, 0));
		$tmp = $tmp."$newComplexType $leftVarName";
		if (1 eq $leftIsStatic && ("Int32" eq $newComplexType || "Int64" eq $newComplexType)) {
			$tmp = $tmp." = $rightData;\n";
		}
		else {
			$tmp = $tmp.";\n";
		}
		push @$dotContexts, $tmp;
	}

	# .cpp
	if (1 eq $dotHCpp) {
		$startSpace = "";
		my $tmp = "";
		if (1 eq $leftIsStatic) {
			if (1 eq $leftIsFinal) { $tmp = $tmp."const "; }
			my $scopePath = $item->currScopePath;
			my $newComplexType = Util::stringTrim(TransElastosType::transComplexVarDefineElastosType($leftVarType, 1));
			$tmp = $tmp."$newComplexType $scopePath"."::"."$leftVarName";
			if (1 eq $leftIsFinal && "String" eq $newComplexType) {
				$tmp = $tmp."($rightData);\n";
			}
			elsif ("Int32" eq $newComplexType || "Int64" eq $newComplexType) {
				$tmp = $tmp.";\n";
			}
			else {
				$tmp = $tmp." = $rightData;\n";
			}
			push @$dotContexts, $tmp;
		}
	}

}

sub polishScope
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	if (0 eq $dotHCpp) {
		my @except;
		push @except, "";
		push @except, "{";
		&polishEmptyLine($dotContexts, \@except);
		$startSpace = Util::stringBeginTrimStr($startSpace, $TAB);
		push @$dotContexts, $startSpace."$item->{ $FileTag::K_SelfData }:\n";
	}
}

sub polishMarco
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	if (0 eq $dotHCpp) {
		&polishEmptyLine($dotContexts);
		push @$dotContexts, $startSpace."$item->{ $FileTag::K_SelfData }"; # selfdata has \n yet.
	}
}

sub polishNamespace
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	if (0 eq $gUsingNamespace) {
		$gUsingNamespace = 1;
		my ($findOk, $outBrother) = $item->lastBrother;
		if (1 eq $findOk) {
			$gUsingNamespaceAfterNode = $outBrother;
			$gUsingNamespaceParentNode = $item->parentNode;
		}
		else {
			print __LINE__." cannot find lastbrother in polishNamespace\n";
			<STDIN>
		}
	}

	&polishEmptyLine($dotContexts);
	push @$dotContexts, $startSpace."$item->{ $FileTag::K_SelfData }";
	push @$dotContexts, "\n";
}

sub polishClassNote
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	&polishEmptyLine($dotContexts);
	my $classNote = $item->{ $FileTag::K_SelfData };
	push @$dotContexts, $classNote;
	push @$dotContexts, "\n";
}

sub polishInclude
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	my ($findOk, $outBrother) = $item->lastBrother;
	if (1 eq $findOk) {
		my $type = $outBrother->{ $FileTag::K_NodeType };
		if ("INCLUDE" ne $type) {
			&polishEmptyLine($dotContexts);
		}
	}
	else {
		&polishEmptyLine($dotContexts);
	}
	my $data = $item->{ $FileTag::K_SelfData };
	push @$dotContexts, $startSpace."$data";
}

sub polishUsingNamespace
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	&polishEmptyLine($dotContexts);
	my $data = $item->{ $FileTag::K_SelfData };
	push @$dotContexts, $startSpace."$data";
}

sub polishEmptyLine
{
	my $contexts = shift;
	my $excepts = shift;
	if (!defined($excepts)) {
		my @empty = ();
		push @empty, "";
		$excepts = \@empty;
	}
	if (@$contexts > 0) {
		my $lastLine = Util::stringTrim($contexts->[@$contexts - 1]);
		if (0 eq Util::isOneOfArray($excepts, $lastLine)) {
			push @$contexts, "\n";
		}
	}
	else {
		push @$contexts, "\n";
	}
}

sub polishReduceEmptyLine
{
	my $contexts = shift;
	my $matchs = shift;
	if (!defined($matchs)) {
		my @empty = ();
		push @empty, "";
		$matchs = \@empty;
	}
	if (@$contexts > 0) {
		my $lastLine = Util::stringTrim($contexts->[@$contexts - 1]);
		if (1 eq Util::isOneOfArray($matchs, $lastLine)) {
			pop @$contexts;
		}
	}
}

sub polishReturn
{
	my $contexts = shift;
	my $funcRet = shift;
	my $startSpace = shift;
	if ("void" ne $funcRet) {
		my $results = TransElastosType::transComplexReturnExpress($funcRet, $startSpace);
		push @$contexts, @$results;
	}
}

sub polishCppControl
{
	my $root = shift;
	if (exists ($root->{ $FileTag::K_SubNodes })) {
		my $childs = $root->{ $FileTag::K_SubNodes };
		for (my $idx=0; $idx<@$childs; ++$idx) {
			my $child = $childs->[ $idx ];
			my $type = $child->{ $FileTag::K_NodeType };
			if ($type eq "FUNC") {
				my $isPureVirtual = $child->{ $FileTag::K_PureVirtual };
				if (defined($isPureVirtual) && 0 eq $isPureVirtual) {
					return 1;
				}
			}
			elsif ($type eq "VAR_DFFINE" || $type eq "VAR_ASSIGNMENT") {
				my $isStatic = $child->{ $FileTag::K_Static };
				if (defined($isStatic) && 1 eq $isStatic) {
					return 1;
				}
			}
			elsif ($type eq "CLASS" || $type eq "INTERFACE") {
				my $needCpp = &polishCppControl($child);
				if (1 eq $needCpp) { return 1; }
			}
		}
	}
	return 0;
}

sub polishBaseToObjectControl
{
	my $root = shift;
	if (exists ($root->{ $FileTag::K_SubNodes })) {
		my $childs = $root->{ $FileTag::K_SubNodes };
		for (my $idx=0; $idx<@$childs; ++$idx) {
			my $child = $childs->[ $idx ];
			my $type = $child->{ $FileTag::K_NodeType };
			if ($type eq "FUNC") {
				my $isStatic = $child->{ $FileTag::K_Static };
				if (0 eq $isStatic) {
					return 1;
				}
			}
			elsif ($type eq "CLASS" || $type eq "INTERFACE") {
				my $needCpp = &polishBaseToObjectControl($child);
				if (1 eq $needCpp) { return 1; }
			}
		}
	}
	return 0;
}

sub tryInsertUsingNamespaceNode
{
	my $using = shift;

	my $hasInserted = 0;
	foreach my $item (@gInsertUsingNamespace) {
		if ($item eq $using) {
			$hasInserted = 1;
			last;
		}
	}

	if (0 eq $hasInserted) {
		push @gInsertUsingNamespace, $using;
		my $usingNamespace = new FileAnalysisStruct; {
			$usingNamespace->{ $FileTag::K_NodeTag } = $FileTag::DC_using_namespace;
			$usingNamespace->{ $FileTag::K_NodeType } = $FileTag::K_UsingNamespace;
			$usingNamespace->{ $FileTag::K_NodeName } = "";
			$usingNamespace->{ $FileTag::K_SelfData } = $using;
			$usingNamespace->{ $FileTag::K_ParNode } = $gUsingNamespaceParentNode;
		}

		my ($findOk, $index) = $gUsingNamespaceAfterNode->getCurrNodeIdxInParent;
		$gUsingNamespaceParentNode->insertChildNodeIdx($index, 1, $usingNamespace);
		$gUsingNamespaceAfterNode = $usingNamespace;
	}
}






1;

