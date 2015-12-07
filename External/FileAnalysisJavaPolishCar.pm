#!/usr/bin/perl;

package FileAnalysisJavaPolishCar;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(  );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;


sub polishAnalisisStruct
{
	my $root = shift;
	my $dotHContext = $root->clone;
	my $dotCppContext = $root->clone;
	&polishInsertMacroAndNamespace($dotHContext, 0);
	&polishInsertMacroAndNamespace($dotCppContext, 1);
	&polishSquence($dotHContext, 0);
	&polishSquence($dotCppContext, 1);
	&polishInsertScope($dotHContext);
	&polishInsertClassNote($dotCppContext);
	&polishInsertIncludeAndUsingNamespace($dotHContext, 0);
	&polishInsertIncludeAndUsingNamespace($dotCppContext, 1);
	return $dotHContext;
}

sub polishInsertMacroAndNamespace
{
	my $root = shift;
	my $dotHCpp = shift;

	my $rootType = $root->{ $FileTag::K_NodeType };
	if ("DOC" eq $rootType) {
		my $childs = $root->{ $FileTag::K_SubNodes };
		my $filePath = $root->{ $FileTag::K_NodeName };
		my $macro = BuildMarco::buildMacro($filePath);
		my $namespaceStartList = BuildNamespace::buildNamespaceStartList($filePath);
		my $namespaceEndList = BuildNamespace::buildNamespaceEndList($filePath);

		my $macroStart = new FileAnalysisStruct; {
			my $selfData;
			$selfData = $selfData."#ifndef $macro\n";
			$selfData = $selfData."#define $macro\n";
			$macroStart->{ $FileTag::K_NodeTag } = $FileTag::DC_macro_start;
			$macroStart->{ $FileTag::K_NodeType } = "MACRO_START";
			$macroStart->{ $FileTag::K_NodeName } = "";
			$macroStart->{ $FileTag::K_SelfData } = $selfData;
			$macroStart->{ $FileTag::K_ParNode } = $root;
		}
		my $macroEnd = new FileAnalysisStruct; {
			my $selfData;
			$selfData = $selfData."#endif // $macro\n";
			$macroEnd->{ $FileTag::K_NodeTag } = $FileTag::DC_macro_end;
			$macroEnd->{ $FileTag::K_NodeType } = "MACRO_END";
			$macroEnd->{ $FileTag::K_NodeName } = "";
			$macroEnd->{ $FileTag::K_SelfData } = $selfData;
			$macroEnd->{ $FileTag::K_ParNode } = $root;
		}
		my $namespaceStart = new FileAnalysisStruct; {
			my $selfData = join "", @$namespaceStartList;
			$namespaceStart->{ $FileTag::K_NodeTag } = $FileTag::DC_namespace_start;
			$namespaceStart->{ $FileTag::K_NodeType } = "NAMESPACE_START";
			$namespaceStart->{ $FileTag::K_NodeName } = "";
			$namespaceStart->{ $FileTag::K_SelfData } = $selfData;
			$namespaceStart->{ $FileTag::K_ParNode } = $root;
		}
		my $namespaceEnd = new FileAnalysisStruct; {
			my $selfData = join "", @$namespaceEndList;
			$namespaceEnd->{ $FileTag::K_NodeTag } = $FileTag::DC_namespace_end;
			$namespaceEnd->{ $FileTag::K_NodeType } = "NAMESPACE_END";
			$namespaceEnd->{ $FileTag::K_NodeName } = "";
			$namespaceEnd->{ $FileTag::K_SelfData } = $selfData;
			$namespaceEnd->{ $FileTag::K_ParNode } = $root;
		}

		my @types = ();
		foreach (@$childs) {
			push @types, $_->{ $FileTag::K_NodeType };
		}

		my $insInfos = &obtInsertMacroAndNamespaceInfo(\@types);
		$root->insertChildNodeIdx($insInfos->{ "MACRO_END_IDX" }, $insInfos->{ "MACRO_END_AFTER" }, $macroEnd);
		$root->insertChildNodeIdx($insInfos->{ "NAME_END_IDX" }, $insInfos->{ "NAME_END_AFTER" }, $namespaceEnd);
		$root->insertChildNodeIdx($insInfos->{ "NAME_START_IDX" }, $insInfos->{ "NAME_START_AFTER" }, $namespaceStart);
		$root->insertChildNodeIdx($insInfos->{ "MACRO_START_IDX" }, $insInfos->{ "MACRO_START_AFTER" }, $macroStart);
	}
}

sub polishInsertScope
{
	my $root = shift;

	my $rootType = $root->{ $FileTag::K_NodeType };
	if ("DOC" eq $rootType) {
		my $childs = $root->{ $FileTag::K_SubNodes };
		my $type;
		foreach (@$childs) {
			$type = $_ ->{ $FileTag::K_NodeType };
			if ("CLASS" eq $type || "INTERFACE" eq $type) {
				&doInsertScope($_);
			}
		}
	}
}

sub polishSquence
{
	my $root = shift;
	my $dotHCpp = shift;

	my $rootType = $root->{ $FileTag::K_NodeType };
	if ("DOC" eq $rootType) {
		if (exists ($root->{ $FileTag::K_SubNodes })) {
			my $subNodes = $root->{ $FileTag::K_SubNodes };
			my $childType;
			foreach my $child (@$subNodes) {
				$childType = $child->{ $FileTag::K_NodeType };
				if ("CLASS" eq $childType || "INTERFACE" eq $childType) {
					&polishSquence($child, $dotHCpp);
				}
			}
		}
	}
	elsif ("CLASS" eq $rootType || "INTERFACE" eq $rootType) {
		if (exists ($root->{ $FileTag::K_SubNodes })) {
			my $subNodes = $root->{ $FileTag::K_SubNodes };
			my $childType;
			$subNodes = &doSquence($subNodes, $dotHCpp);
			$root->{ $FileTag::K_SubNodes } = $subNodes;
			foreach my $child (@$subNodes) {
				$childType = $child->{ $FileTag::K_NodeType };
				if ("CLASS" eq $childType || "INTERFACE" eq $childType) {
					&polishSquence($child, $dotHCpp);
				}
			}
		}
	}
}

sub polishInsertClassNote
{
	my $root = shift;
	my $rootType = $root->{ $FileTag::K_NodeType };
	my $childs = $root->{ $FileTag::K_SubNodes };
	my $currRootNeedInsertNote = &checkClassWhetherNeedNote($root);
	my $currClassInsert = 0;
	my $type;
	for (my $idx=0; $idx<@$childs; ++$idx) {
		my $item = $childs->[ $idx ];
		$type = $item ->{ $FileTag::K_NodeType };
		if ("CLASS" eq $type || "INTERFACE" eq $type) {
			&polishInsertClassNote($item);
		}
		# if has no children donot insert class note
		if (1 eq $currRootNeedInsertNote) {
			if (0 eq $currClassInsert) {
				if ("VAR_DEFINE" eq $type || "VAR_ASSIGNMENT" eq $type || "FUNC" eq $type) {
					my $classNote = new FileAnalysisStruct; {
						my $scopePath = $item->currScopePath;
						my $cppClassStartNote = Util::buildCppClassNote($scopePath);
						$classNote->{ $FileTag::K_NodeTag } = $FileTag::DC_class_note;
						$classNote->{ $FileTag::K_NodeType } = "CLASS_NOTE";
						$classNote->{ $FileTag::K_NodeName } = $scopePath;
						$classNote->{ $FileTag::K_SelfData } = $cppClassStartNote;
						$classNote->{ $FileTag::K_ParNode } = $root;
						$root->insertChildNodeIdx($idx, 0, $classNote);
						++$idx;
						$currClassInsert = 1;
					}
				}
			}
		}
	}
}

sub polishInsertIncludeAndUsingNamespace
{
	my $root = shift;
	my $dotHCpp = shift;

	if (0 eq $dotHCpp) {
		# insert which?
		my $includes = BuildIncludes::buildIncludes($root);
		my $includeStr = join "", @$includes;
		my ($findOk, $node, $index) = $root->firstChildSpecifyType("MACRO_START");
		if (1 eq $findOk) {
			my $includeNode = new FileAnalysisStruct; {
				$includeNode->{ $FileTag::K_NodeTag } = $FileTag::DC_include;
				$includeNode->{ $FileTag::K_NodeType } = "INCLUDE";
				$includeNode->{ $FileTag::K_NodeName } = "";
				$includeNode->{ $FileTag::K_SelfData } = $includeStr;
				$includeNode->{ $FileTag::K_ParNode } = $root;
			}
			$root->insertChildNodeIdx($index, 1, $includeNode);
		}

		my $usingNamespaces = BuildNamespace::buildUsingnspaces($root);
		my $usingNamespaceStr = join "", @$usingNamespaces;
		my $usingNamespaceNode = new FileAnalysisStruct; {
			$usingNamespaceNode->{ $FileTag::K_NodeTag } = $FileTag::DC_using_namespace;
			$usingNamespaceNode->{ $FileTag::K_NodeType } = "USING_NAMESPACE";
			$usingNamespaceNode->{ $FileTag::K_NodeName } = "";
			$usingNamespaceNode->{ $FileTag::K_SelfData } = $usingNamespaceStr;
			$usingNamespaceNode->{ $FileTag::K_ParNode } = $root;
		}
		($findOk, $node, $index) = $root->firstChildSpecifyType("NAMESPACE_START");
		if (1 eq $findOk) {
			$root->insertChildNodeIdx($index, 0, $usingNamespaceNode);
		}
		else {
			print __LINE__." firstChildSpecifyType(NAMESPACE_START) failed, STDIN\n";
			<STDIN>;
		}
	}
	elsif (1 eq $dotHCpp) {
		my $filePath = $root->{ $FileTag::K_NodeName };
		if ($filePath =~ m/\/(elastos\/droid\/.*)$/) {
			my $relativePath = $1;
			$relativePath =~ s/\.\w+$/\.h/;
			$relativePath =~ s/\s*$//;
			my $includeNode = new FileAnalysisStruct; {
				my $selfData = "#include \"$relativePath\"\n";
				$includeNode->{ $FileTag::K_NodeTag } = $FileTag::DC_include;
				$includeNode->{ $FileTag::K_NodeType } = "INCLUDE";
				$includeNode->{ $FileTag::K_NodeName } = "";
				$includeNode->{ $FileTag::K_SelfData } = $selfData;
				$includeNode->{ $FileTag::K_ParNode } = $root;
			}
			$root->insertChildNodeIdx(0, 0, $includeNode);
		}
	}
}

sub checkClassWhetherNeedNote
{
	my $root = shift;
	my $childs = $root->{ $FileTag::K_SubNodes };
	for (my $idx=0; $idx<@$childs; ++$idx) {
		my $item = $childs->[ $idx ];
		my $type = $item ->{ $FileTag::K_NodeType };
		if ("CLASS" eq $type || "INTERFACE" eq $type) {
			if (1 eq &checkClassWhetherNeedNote($item)) {
				return 1;
			}
		}
		elsif ("FUNC" eq $type) {
			if (exists ($item->{ $FileTag::K_PureVirtual }) && exists ($item->{ $FileTag::K_Abstract })) {
				if (0 eq $item->{ $FileTag::K_PureVirtual } && 0 eq $item->{ $FileTag::K_Abstract }) {
					return 1;
				}
			}
			else {
				return 1;
			}
		}
		elsif ("VAR_DEFINE" eq $type || "VAR_ASSIGNMENT" eq $type) {
			if (exists ($item->{ $FileTag::K_Static })) {
				if (1 eq $item->{ $FileTag::K_Static }) {
					return 1;
				}
			}
		}
	}
	return 0;
}

sub obtInsertMacroAndNamespaceInfo
{
	my $types = shift;
	my %insertInfos = ();

	$insertInfos{ "MACRO_END_IDX" } = @$types - 1;
	$insertInfos{ "MACRO_END_AFTER" } = 1;

	$insertInfos{ "NAME_END_IDX" } = @$types - 1;
	$insertInfos{ "NAME_END_AFTER" } = 1;

	my $idx = 0;
	while ("NOTE" eq $types->[$idx]) { ++$idx; }
	$insertInfos{ "MACRO_START_IDX" } = $idx;
	$insertInfos{ "MACRO_START_AFTER" } = 0;

	while ("IMPORT" eq $types->[$idx] || "PACKAGE" eq $types->[$idx]) { ++$idx; }
	$insertInfos{ "NAME_START_IDX" } = $idx;
	$insertInfos{ "NAME_START_AFTER" } = 0;

	return \%insertInfos;
}

sub doInsertScope
{
	my $node = shift;
	if (exists ($node->{ $FileTag::K_SubNodes })) {
		my $childs = $node->{ $FileTag::K_SubNodes };
		my $lastScope = "";
		my $scope = "";
		my $lastType = "";
		my $type = "";
		my $item;
		for (my $idx=@$childs-1; $idx>=0; --$idx) {
			$item = $childs->[$idx];
			&doInsertScope($item);

			my $tempNodeName = $item->{ $FileTag::K_NodeName };
			#print __LINE__." lastScope=$lastScope: \$lastType=$lastType, \$type=$type, \$tempNodeName=$tempNodeName\n";

			my $needInsert = 0;
			my $insertAfter = 1;
			# compare curr and last but insert curr after
			{
				next if (!exists ($item ->{ $FileTag::K_Scope }));
				next if (!exists ($item ->{ $FileTag::K_NodeType }));

				my $realType = $item ->{ $FileTag::K_NodeType };
				#print __LINE__." \$realType=$realType\n";
				if (1 eq &isUsefullTypeForScope($realType)) {
					$type = $realType;
				}
				else { next; }

				$scope = $item ->{ $FileTag::K_Scope };
				if ($lastScope ne $scope && "" ne $lastScope) {
					$needInsert = 1;
					$insertAfter = 1;
				}
				elsif ($lastScope eq $scope && "" ne $scope) {
					#print __LINE__." \$lastType=$lastType, \$type=$type\n";
					if (0 eq $node->scopeIsNodeTypeSame($lastType, $type)) {
						#print __LINE__." scopeIsNodeTypeSame=0, \$lastType=$lastType, \$type=$type\n";
						$needInsert = 1;
						$insertAfter = 1;
					}
				}
			}

			if (1 eq $needInsert) {
				&doInsertScopeByIndex($node, $lastScope, $idx, $insertAfter);
			}
			# first node must be has a scope
			if (0 eq $idx) {
				&doInsertScopeByIndex($node, $scope, $idx, 0);
			}

			if ("" ne $type) { $lastType = $type; }
			if ("" ne $scope) { $lastScope = $scope; }
		}
	}
}

sub doInsertScopeByIndex
{
	my $node = shift;
	my $scope = shift;
	my $index = shift;
	my $after = shift;
	my $scopeNode = new FileAnalysisStruct;
	$scopeNode->{ $FileTag::K_NodeTag } = $FileTag::DC_scope;
	$scopeNode->{ $FileTag::K_NodeType } = "SCOPE";
	$scopeNode->{ $FileTag::K_NodeName } = $scope;
	$scopeNode->{ $FileTag::K_SelfData } = $scope;
	$scopeNode->{ $FileTag::K_ParNode } = $node;
	my $childs = $node->{ $FileTag::K_SubNodes };
	$node->insertChildNodeIdx($index, $after, $scopeNode);
}

sub doSquence
{
	my $array = shift;
	my $dotHCpp = shift;

	my $arrCnt = @$array;
	my @newKeySqu; {
		my $type;
		my $scope;
		my $value;

		my $newKey = &doSquenceInnerGetKey;
		foreach my $item (@$array) {
			$type = $item->{ $FileTag::K_NodeType };
			$scope = $item->{ $FileTag::K_Scope };
			$value = $newKey->{ "VALUE" };
			if ("CLASS" eq $type || "INTERFACE" eq $type || "FUNC" eq $type || "VAR_DEFINE" eq $type || "VAR_ASSIGNMENT" eq $type) {
				push @$value, $item;
				$newKey->{ "SCOPE" } = $scope;
				$newKey->{ "TYPE" } = $type;
				if (exists ($item->{ $FileTag::K_Return })) { $newKey->{ "RETURN" } = $item->{ $FileTag::K_Return }; }
				push @newKeySqu, $newKey;
				$newKey = &doSquenceInnerGetKey;
			}
			else {
				push @$value, $item;
			}
		}
	}

	my @result = (); {
		my @innClassPub = ();
		my @innClassPro = ();
		my @innClassPri = ();
		my @funcConsPub = ();
		my @funcConsPro = ();
		my @funcConsPri = ();
		my @funcCommPub = ();
		my @funcCommPro = ();
		my @funcCommPri = ();
		my @varPub = ();
		my @varPro = ();
		my @varPri = ();

		my $type;
		my $scope;
		my $value;
		my $return;
		foreach my $item (@newKeySqu) {
			$type = $item->{ "TYPE" };
			$scope = $item->{ "SCOPE" };
			$value = $item->{ "VALUE" };
			if ("CLASS" eq $type || "INTERFACE" eq $type) {
				if ("public" eq $scope) { push @innClassPub, @$value; }
				elsif ("protected" eq $scope) { push @innClassPro, @$value; }
				elsif ("private" eq $scope) { push @innClassPri, @$value; }
			}
			elsif ("VAR_DEFINE" eq $type) {
				if ("public" eq $scope) { push @varPub, @$value; }
				elsif ("protected" eq $scope) { push @varPro, @$value; }
				elsif ("private" eq $scope) { push @varPri, @$value; }
			}
			elsif ("VAR_ASSIGNMENT" eq $type) {
				if ("public" eq $scope) { push @varPub, @$value; }
				elsif ("protected" eq $scope) { push @varPro, @$value; }
				elsif ("private" eq $scope) { push @varPri, @$value; }
			}
			elsif ("FUNC" eq $type) {
				$return = $item->{ "RETURN" };
				if ("" eq $return && "public" eq $scope) { push @funcConsPub, @$value; }
				elsif ("" ne $return && "public" eq $scope) { push @funcCommPub, @$value; }
				elsif ("" eq $return && "protected" eq $scope) { push @funcConsPro, @$value; }
				elsif ("" ne $return && "protected" eq $scope) { push @funcCommPro, @$value; }
				elsif ("" eq $return && "private" eq $scope) { push @funcConsPri, @$value; }
				elsif ("" ne $return && "private" eq $scope) { push @funcCommPri, @$value; }
			}
		}

		if (0 eq $dotHCpp) {
			push @result, @innClassPub;
			push @result, @innClassPro;
			push @result, @innClassPri;
			push @result, @funcConsPub;
			push @result, @funcCommPub;
			push @result, @funcConsPro;
			push @result, @funcCommPro;
			push @result, @funcConsPri;
			push @result, @funcCommPri;
			push @result, @varPub;
			push @result, @varPro;
			push @result, @varPri;
		}
		else {
			push @result, @innClassPub;
			push @result, @innClassPro;
			push @result, @innClassPri;
			push @result, @varPub;
			push @result, @varPro;
			push @result, @varPri;
			push @result, @funcConsPub;
			push @result, @funcCommPub;
			push @result, @funcConsPro;
			push @result, @funcCommPro;
			push @result, @funcConsPri;
			push @result, @funcCommPri;
		}

=pod
		my $classpub = @innClassPub;
		my $classpro = @innClassPro;
		my $classpri = @innClassPri;
		my $strupub = @funcConsPub;
		my $strupro = @funcConsPro;
		my $strupri = @funcConsPri;
		my $commpub = @funcCommPub;
		my $commpro = @funcCommPro;
		my $commpri = @funcCommPri;
		my $vardpub = @varPub;
		my $vardpro = @varPro;
		my $vardpri = @varPri;
		print " \$classpub=$classpub, \$classpro=$classpro, \$classpri=$classpri\n";
		print " \$strupub=$strupub, \$strupro=$strupro, \$strupri=$strupri\n";
		print " \$commpub=$commpub, \$commpro=$commpro, \$commpri=$commpri\n";
		print " \$vardpub=$vardpub, \$vardpro=$vardpro, \$vardpri=$vardpri\n";
=cut

	}
	return \@result;
}

sub doSquenceInnerGetKey
{
	my %key = ();
	$key{ "SCOPE" } = "";
	$key{ "TYPE" } = "";
	$key{ "RETURN" } = "";
	my @empty = ();
	$key{ "VALUE" } = \@empty;
	return \%key;
}

my @gAllUsefullTypeForScope = ("CLASS", "INTERFACE", "FUNC", "VAR_DEFINE", "VAR_ASSIGNMENT");
sub isUsefullTypeForScope
{
	my $type = shift;
	if (grep { $_ eq Util::stringTrim($type) } @gAllUsefullTypeForScope) { return 1; }
	return 0;
}


1;
