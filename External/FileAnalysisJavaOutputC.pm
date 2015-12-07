#!/usr/bin/perl;

package FileAnalysisJavaOutputC;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( outputAnalisisStruct, outputRoot );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;
use TransElastosType;

our $TAB = "    ";
our $gCurrDotHRoot;

sub outputAnalisisStruct
{
	my $dotHRoot = shift;
	my $dotCppRoot = shift;
	my $filePath = $dotHRoot->{ $FileTag::K_NodeName };
	my $dotHPath = $filePath;
	$dotHPath =~ s/\.java/\.h/g;
	my $dotCppPath = $filePath;
	$dotCppPath =~ s/\.java/\.cpp/g;
	my ($dotHContext, $dotCppContext) = &outputRoot($dotHRoot, $dotCppRoot);
	FileOperate::writeFile($dotHPath, $dotHContext);
	if (1 eq &outputCppControl($dotCppRoot)) {
		FileOperate::writeFile($dotCppPath, $dotCppContext);
	}
	else {
		unlink $dotCppPath;
		print __LINE__." noneedcpp: $dotCppPath\n";
	}
}

sub outputRoot
{
	my $dotHRoot = shift;
	my $dotCppRoot = shift;
	$gCurrDotHRoot = $dotHRoot;
	my @dotHContexts = ();
	my @dotCppContexts = ();

	#push @dotHContexts, "// wuweizuo automatic build .h file from .java file.\n";
	#push @dotCppContexts, "// wuweizuo automatic build .cpp file from .java file.\n";
	my $startSpace = "";
	# .h
	{
		my $childs = $dotHRoot->{ $FileTag::K_SubNodes };
		foreach (@$childs) {
			&outputContext($_, \@dotHContexts, 0, $startSpace);
		}
	}
	# .cpp
	{
		my $childs = $dotCppRoot->{ $FileTag::K_SubNodes };
		foreach (@$childs) {
			&outputContext($_, \@dotCppContexts, 1, $startSpace);
		}
	}

	push @dotHContexts, "\n";
	push @dotCppContexts, "\n";
	return (\@dotHContexts, \@dotCppContexts);
}

sub outputContext
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
    		&outputEmpty($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_package eq $tag) {
    		&outputPackage($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_import eq $tag) {
    		&outputImport($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_astart eq $tag) {
    		&outputAStart($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_note eq $tag) {
    		&outputNote($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_class eq $tag) {
    		&outputClass($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_interface eq $tag) {
    		&outputInterface($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
		elsif ($FileTag::DC_function_define eq $tag) {
    		&outputFuncDefine($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
		elsif ($FileTag::DC_function_call eq $tag) {
    		&outputFuncCall($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_if eq $tag) {
    		&outputLogicIf($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_elseif eq $tag) {
    		&outputLogicElseIf($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_else eq $tag) {
    		&outputLogicElse($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_switch eq $tag) {
    		&outputLogicSwitch($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_while eq $tag) {
    		&outputLogicWhile($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_logic_for eq $tag) {
    		&outputLogicFor($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_var_define eq $tag) {
    		&outputVarDefine($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_var_assignment eq $tag) {
    		&outputVarAssignment($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	# insert by polish
    	elsif ($FileTag::DC_scope eq $tag) {
			&outputScope($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_namespace_start eq $tag) {
			&outputNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_namespace_end eq $tag) {
			&outputNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_macro_start eq $tag) {
			&outputMarco($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_macro_end eq $tag) {
			&outputMarco($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_class_note eq $tag) {
			&outputClassNote($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_include eq $tag) {
			&outputInclude($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_using_namespace eq $tag) {
			&outputUsingNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	else {
    		my $strTag = FileTag::getTagString($tag);
    		print __LINE__."[E] \$DC var match failed. \$strTag=$strTag\n";
    	}
	}

	return $dotContexts;
}


sub outputEmpty
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
	push @$dotContexts, "\n";
}

sub outputPackage
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
	if (0 eq $dotHCpp) {
		my ($findOk, $outBrother) = $item->lastBrother;
		if (1 eq $findOk) {
			my $type = $outBrother->{ $FileTag::K_NodeType };
			if ("PACKAGE" ne $type && "IMPORT" ne $type) {
				&outputEmptyLine($dotContexts);
			}
		}
		else {
			&outputEmptyLine($dotContexts);
		}
		my $data = $item->{ $FileTag::K_SelfData };
		push @$dotContexts, $startSpace."// $data\n";
	}
}

sub outputImport
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
	if (0 eq $dotHCpp) {
		my ($findOk, $outBrother) = $item->lastBrother;
		if (1 eq $findOk) {
			my $type = $outBrother->{ $FileTag::K_NodeType };
			if ("PACKAGE" ne $type && "IMPORT" ne $type) {
				&outputEmptyLine($dotContexts);
			}
		}
		else {
			&outputEmptyLine($dotContexts);
		}
		my $data = $item->{ $FileTag::K_SelfData };
		push @$dotContexts, $startSpace."// $data\n";
	}
}

sub outputAStart
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
	if (0 eq $dotHCpp) {
		my $data = $item->{ $FileTag::K_SelfData };
		push @$dotContexts, $startSpace."// $data\n";
	}
}

sub outputNote
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;
	if (0 eq $dotHCpp) {
		my $data = $item->{ $FileTag::K_SelfData };
		push @$dotContexts, $startSpace.$data."\n";
	}
}

sub outputClass
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

    my $className = $item->{ $FileTag::K_NodeName };
    my $parents = $item->{ $FileTag::K_Parents };

    #print __LINE__." outputClass: \$className=$className\n";

	if (0 eq $dotHCpp) {
		my @classDefine = ();
		if (1 eq outputBaseToObjectControl($item)) {
			if (0 == @$parents) {
				push @classDefine, $startSpace."class $className\n";
				push @classDefine, $startSpace."    : public Object\n";
			}
			elsif (1 == @$parents) {
				my $fmtParName = $parents->[0];
				#$fmtParName =~ s/\./::/g;
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				push @classDefine, $startSpace."class $className\n";
				push @classDefine, $startSpace."    : public Object\n";
				push @classDefine, $startSpace."    , public $fmtParName\n";
			}
			else {
				push @classDefine, $startSpace."class $className\n";
				push @classDefine, $startSpace."    : public Object\n";
				my $fmtParName = $parents->[0];
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				push @classDefine, $startSpace."    , public $fmtParName\n";
				for (my $idx=1; $idx<@$parents; ++$idx) {
					$fmtParName = $parents->[$idx];
					#$fmtParName =~ s/\./::/g;
					$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
					push @classDefine, $startSpace."    , public $fmtParName\n";
				}
			}
		}
		else {
			if (0 == @$parents) {
				push @classDefine, $startSpace."class $className\n";
			}
			elsif (1 == @$parents) {
				my $fmtParName = $parents->[0];
				#$fmtParName =~ s/\./::/g;
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				push @classDefine, $startSpace."class $className\n";
				push @classDefine, $startSpace."    : public $fmtParName\n";
			}
			else {
				push @classDefine, $startSpace."class $className\n";
				my $fmtParName = $parents->[0];
				#$fmtParName =~ s/\./::/g;
				$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
				push @classDefine, $startSpace."    : public $fmtParName\n";
				for (my $idx=1; $idx<@$parents; ++$idx) {
					$fmtParName = $parents->[$idx];
					#$fmtParName =~ s/\./::/g;
					$fmtParName = TransElastosType::transParClassElastosType($gCurrDotHRoot, $fmtParName);
					push @classDefine, $startSpace."    , public $fmtParName\n";
				}
			}
		}

		push @$dotContexts, @classDefine;
		push @$dotContexts, $startSpace."{\n";

		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&outputContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}

		&outputReduceEmptyLine($dotContexts);
		push @$dotContexts, $startSpace."};\n";
		push @$dotContexts, "\n";
	}
	else {
		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&outputContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}
	}
}

sub outputInterface
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
			push @classDefine, $startSpace."class $className\n";
		}
		elsif (1 == @$parents) {
			my $fmtParName = $parents->[0];
			$fmtParName =~ s/\./::/g;
			push @classDefine, $startSpace."class $className : public $fmtParName\n";
		}
		else {
			push @classDefine, $startSpace."class $className\n";
			my $fmtParName = $parents->[0];
			$fmtParName =~ s/\./::/g;
			push @classDefine, $startSpace."    : public $fmtParName\n";
			for (my $idx=1; $idx<@$parents; ++$idx) {
				$fmtParName = $parents->[$idx];
				$fmtParName =~ s/\./::/g;
				push @classDefine, $startSpace."    , public $fmtParName\n";
			}
		}
		push @$dotContexts, @classDefine;
		push @$dotContexts, $startSpace."{\n";

		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&outputContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}

		&outputReduceEmptyLine($dotContexts);
		push @$dotContexts, $startSpace."};\n";
		push @$dotContexts, "\n";
	}
	else {
		if (exists ($item->{ $FileTag::K_SubNodes })) {
			my $childs = $item->{ $FileTag::K_SubNodes };
			foreach (@$childs) {
				&outputContext($_, $dotContexts, $dotHCpp, $startSpace.$TAB);
			}
		}
	}
}

sub outputFuncDefine
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
		print __LINE__." virtual isnot defined, \$funcName=$funcName\n";
		<STDIN>;
   	}

	# .h
	if (0 eq $dotHCpp) {
		my @tmps;
		my $tmp = "";
		$tmp = $tmp.$startSpace;
		if (1 eq $isSynchronized) {
			$tmp = $tmp."// synchronized\n";
			push @tmps, $tmp;
		}

		$tmp = "";
		$tmp = $tmp.$startSpace;
		if (1 eq $isVirtual) { $tmp = $tmp."virtual "; }
		if (1 eq $isStatic) { $tmp = $tmp."static "; }
		if (1 eq $isFinal) { $tmp = $tmp."const "; }
		if ("" ne $funcRet) {
			# equal "public" and isnot override, it will be trans to CAR interface, so return is CARAPI,
			# and source return will trans to out param
			if (1 eq $isCarFunc) {
				$tmp = $tmp."CARAPI ";
			}
			elsif ("void" eq $funcRet && "public" ne $scope) {
				$tmp = $tmp."CARAPI_(void) ";
			}
			else {
				my $dotHFuncRet = TransElastosType::transComplexReturnElastosType($funcRet, 0);
				$tmp = $tmp."$dotHFuncRet ";
			}
		}
		if ("" ne $funcName) { $tmp = $tmp."$funcName("; }

		if (0 == @$params) {
			if (1 eq $isCarFunc && "" ne $funcRet && "void" ne $funcRet) {
				$tmp = $tmp."\n";
				push @tmps, $tmp;

				my $newFuncRet = TransElastosType::transOutParamElastosType($funcRet);
				my $startSpaceTmp = $startSpace.$TAB;
				$tmp = $startSpaceTmp."/* [out] */ $newFuncRet result)";
			}
			else {
				$tmp = $tmp.")";
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
				my $newParmType = TransElastosType::transComplexParamElastosType($parmType);
				#print __LINE__." transParam: $parmType => $newParmType\n";
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
		&outputEmptyLine($dotContexts);
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
			&outputReturn(\@tmps, $dotCppFuncRet, $startSpace);
		}
		push @tmps, "}\n";
		push @tmps, "\n";
		push @$dotContexts, @tmps;
	}
}

sub outputFuncCall
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub outputLogicIf
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub outputLogicElseIf
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub outputLogicElse
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub outputLogicSwitch
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub outputLogicWhile
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;


}

sub outputLogicFor
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

}

sub outputVarDefine
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

sub outputVarAssignment
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

sub outputScope
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
		&outputEmptyLine($dotContexts, \@except);
		$startSpace = Util::stringBeginTrimStr($startSpace, $TAB);
		push @$dotContexts, $startSpace."$item->{ $FileTag::K_SelfData }:\n";
	}
}

sub outputMarco
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	if (0 eq $dotHCpp) {
		&outputEmptyLine($dotContexts);
		push @$dotContexts, $startSpace."$item->{ $FileTag::K_SelfData }"; # selfdata has \n yet.
	}
}

sub outputNamespace
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	&outputEmptyLine($dotContexts);
	push @$dotContexts, $startSpace."$item->{ $FileTag::K_SelfData }";
	push @$dotContexts, "\n";
}

sub outputClassNote
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	&outputEmptyLine($dotContexts);
	my $classNote = $item->{ $FileTag::K_SelfData };
	push @$dotContexts, $classNote;
	push @$dotContexts, "\n";
}

sub outputInclude
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
			&outputEmptyLine($dotContexts);
		}
	}
	else {
		&outputEmptyLine($dotContexts);
	}
	my $data = $item->{ $FileTag::K_SelfData };
	push @$dotContexts, $startSpace."$data";
}

sub outputUsingNamespace
{
	my $tag = shift;
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	my $reg = qw/^using /;
	&outputEmptyLine($dotContexts, "", 1, $reg, 0, 1);

	my $data = $item->{ $FileTag::K_SelfData };
	print __LINE__." outputUsingNamespace: \$data=[$data]\n";
	push @$dotContexts, $startSpace."$data";
}

sub outputEmptyLine
{
	my $contexts = shift;
	my $excepts = shift;
	my $isReg = shift;
	my $reg = shift;
	my $machRegInsert = shift;
	my $nomachRegInsert = shift;
	if (defined($isReg) && defined($reg) && defined($machRegInsert) && defined($nomachRegInsert)) {
		my $lastLine = Util::stringTrim($contexts->[@$contexts - 1]);
		print __LINE__." \$lastLine=$lastLine, \$reg=[$reg]\n";
		if ($lastLine =~ m/$reg/) {
			if (1 eq $machRegInsert) {
				push @$contexts, "\n";
				print __LINE__." \$machRegInsert, push n\n";
			}
		}
		else {
			if ($lastLine !~ m/^\s*$/) {
				if (1 eq $nomachRegInsert) {
					push @$contexts, "\n";
					print __LINE__." \$nomachRegInsert, push n\n";
				}
			}
		}
	}
	else {
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
}

sub outputReduceEmptyLine
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

sub outputReturn
{
	my $contexts = shift;
	my $funcRet = shift;
	my $startSpace = shift;
	if ("void" ne $funcRet) {
		my $results = TransElastosType::transComplexReturnExpress($funcRet, $startSpace);
		push @$contexts, @$results;
	}
}

sub outputCppControl
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
				my $needCpp = &outputCppControl($child);
				if (1 eq $needCpp) { return 1; }
			}
		}
	}
	return 0;
}

sub outputBaseToObjectControl
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
				my $needCpp = &outputBaseToObjectControl($child);
				if (1 eq $needCpp) { return 1; }
			}
		}
	}
	return 0;
}


1;
