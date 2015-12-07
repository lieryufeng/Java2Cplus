#!/usr/bin/perl;

package FileAnalysisStruct;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( createRootNode, getRootNode, getInnerClassSeq, getSpecifyTypeNodeUpwardRecursive, clear, getSubsNodes, appendChildNode, insertChildNodeIdx, getParType );
use strict;
use warnings;
use FileTag;

my $gRoot;
my $gInnerClassSeq;

sub new
{
	my $class = shift;
	my %this = ();
	$this{ $FileTag::K_NodeType } = "";
	$this{ $FileTag::K_NodeTag } = -1;
	$this{ $FileTag::K_NodeName } = "";
	#$this{ $FileTag::K_SelfData }; # data is a hash or single string data
	#$this{ $FileTag::K_ParNode };
	my @emptySubs = ();
	$this{ $FileTag::K_SubNodes } = \@emptySubs;
	bless \%this, $class;
	return \%this;
}

sub createRootNode
{
    my $class = shift;
    my $srcFilePath = shift;
    my %this = ();
    $gRoot = \%this;
	$this{ $FileTag::K_NodeType } = "DOC";
	$this{ $FileTag::K_NodeTag } = -1;
	$this{ $FileTag::K_NodeName } = "$srcFilePath";
	#$this{ $FileTag::K_SelfData }; # data is a hash or single string data
	#$this{ $FileTag::K_ParNode };
	my @emptySubs = ();
	$this{ $FileTag::K_SubNodes } = \@emptySubs;
	my @emptyInnerClassSeq = ();
	$gInnerClassSeq = \@emptyInnerClassSeq;
	$this{ $FileTag::K_InnClassSeq } = \@emptyInnerClassSeq;
	bless \%this, $class;
	return \%this;
}

sub clone
{
	my $this = shift;
	my $result = new FileAnalysisStruct;

	my @keys = keys %$this;
	my $keyCnt = @keys;
	foreach my $key (@keys) {
		my $val = $this->{ $key };
		next if (!defined($val));
		my $sign = ref($val);
		if ("FileAnalysisStruct" eq ref($val)) {
			my $cloneVal = &cloneNode($val, $result);
			$result->{ $key } = $cloneVal;
		}
		elsif ("SCALAR" eq ref($val)) {
			my $cloneVal = &cloneScalar($val, $result);
			$result->{ $key } = $cloneVal;
		}
		elsif ("HASH" eq ref($val)) {
			if ($FileTag::K_ParNode ne $key) {
				my $cloneVal = &cloneHash($val, $result);
				$result->{ $key } = $cloneVal;
			}
		}
		elsif ("ARRAY" eq ref($val)) {
			my $cloneVal = &cloneArray($val, $result);
			$result->{ $key } = $cloneVal;
		}
		else {
			my $cloneVal = &cloneScalar($val, $result);
			$result->{ $key } = $cloneVal;
		}
	}

	return $result;
}

sub cloneNode
{
	my $this = shift;
	my $par = shift;
	my $result = new FileAnalysisStruct;

	my @keys = keys %$this;
	my $keyCnt = @keys;
	foreach my $key (@keys) {
		my $val = $this->{ $key };
		next if (!defined($val));
		my $sign = ref($val);
		if ("FileAnalysisStruct" eq ref($val)) {
			if ($FileTag::K_ParNode eq $key) {
				$result->{ $key } = $par;
			}
			else {
				my $cloneVal = &cloneNode($val, $result);
				$result->{ $key } = $cloneVal;
			}
		}
		elsif ("SCALAR" eq ref($val)) {
			my $cloneVal = &cloneScalar($val, $result);
			$result->{ $key } = $cloneVal;
		}
		elsif ("HASH" eq ref($val)) {
			my $cloneVal = &cloneHash($val, $result);
			$result->{ $key } = $cloneVal;
		}
		elsif ("ARRAY" eq ref($val)) {
			my $cloneVal = &cloneArray($val, $result);
			$result->{ $key } = $cloneVal;
		}
		else {
			my $cloneVal = &cloneScalar($val, $result);
			$result->{ $key } = $cloneVal;
		}
	}

	return $result;
}

sub cloneHash
{
	my $this = shift;
	my $par = shift;
	my %result = ();

	my @keys = keys %$this;
	my $keyCnt = @keys;
	foreach my $key (@keys) {
		my $val = $this->{ $key };
		next if (!defined($val));
		if ("FileAnalysisStruct" eq ref($val)) {
			if ($FileTag::K_ParNode eq $key) {
				$result{ $key } = $par;
			}
			else {
				my $cloneVal = &cloneNode($val, $par);
				$result{ $key } = $cloneVal;
			}
		}
		elsif ("SCALAR" eq ref($val)) {
			my $cloneVal = &cloneScalar($val, $par);
			$result{ $key } = $cloneVal;
		}
		elsif ("HASH" eq ref($val)) {
			my $cloneVal = &cloneHash($val, $par);
			$result{ $key } = $cloneVal;
		}
		elsif ("ARRAY" eq ref($val)) {
			my $cloneVal = &cloneArray($val, $par);
			$result{ $key } = $cloneVal;
		}
		else {
			my $cloneVal = &cloneScalar($val, $par);
			$result{ $key } = $cloneVal;
		}
	}

	return \%result;
}

sub cloneScalar
{
	my $this = shift;
	my $par = shift;
	my $result = $this;
	return $result;
}

sub cloneArray
{
	my $this = shift;
	my $par = shift;
	my @result = ();
	my $arrCnt = @$this;
	foreach my $val (@$this) {
		next if (!defined($val));
		my $sign = ref($val);
		if ("FileAnalysisStruct" eq ref($val)) {
			my $cloneVal = &cloneNode($val, $par);
			push @result, $cloneVal;
		}
		elsif ("SCALAR" eq ref($val)) {
			my $cloneVal = &cloneScalar($val, $par);
			push @result, $cloneVal;
		}
		elsif ("HASH" eq ref($val)) {
			my $cloneVal = &cloneHash($val, $par);
			push @result, $cloneVal;
		}
		elsif ("ARRAY" eq ref($val)) {
			my $cloneVal = &cloneArray($val, $par);
			push @result, $cloneVal;
		}
		else {
			my $cloneVal = &cloneScalar($val, $par);
			push @result, $cloneVal;
		}
	}

	return \@result;
}

sub getRootNode
{
	return $gRoot;
}

sub getInnerClassSeq
{
	return $gInnerClassSeq;
}

sub getSpecifyTypeNodeUpwardRecursive
{
	my $this = shift;
	my $type = shift;
	if (exists ($this->{ $FileTag::K_ParNode })) {
		my $parNode = $this->{ $FileTag::K_ParNode };
		if (exists ($parNode->{ $FileTag::K_NodeType })) {
			my $nodeType = $parNode->{ $FileTag::K_NodeType };
			if ($nodeType eq $type) {
				return $parNode;
			}
			else {
				return $parNode->getSpecifyTypeNodeUpwardRecursive($type);
			}
		}
	}
	print __LINE__." upward ParNode is not exists\n";
}

sub getMainClassOrInterface
{
	my $this = shift;
	my $currType = "";
	if (exists ($this->{ $FileTag::K_NodeType })) {
		$currType = $this->{ $FileTag::K_NodeType };
		if ("DOC" eq $currType) {
			my $children = $this->{ $FileTag::K_SubNodes };
			foreach my $item (@$children) {
				my $type = $item->{ $FileTag::K_NodeType };
				if ("CLASS" eq $type || "INTERFACE" eq $type) {
					return $item;
				}
			}
		}
	}

	if (exists ($this->{ $FileTag::K_ParNode })) {
		my $parNode = $this->{ $FileTag::K_ParNode };
		if (exists ($parNode->{ $FileTag::K_NodeType })) {
			my $parType = $parNode->{ $FileTag::K_NodeType };
			if (($currType eq "CLASS" || $currType eq "INTERFACE") && $parType eq "DOC") {
				return $this;
			}
			else {
				return $parNode->getMainClassOrInterface;
			}
		}
	}
	print __LINE__." getMainClassOrInterface failed, main class or interrface is not exists\n";
}

sub getCurrNodeUpwardFirstClassOrInterface
{
	my $this = shift;
	if (exists ($this->{ $FileTag::K_ParNode })) {
		my $parNode = $this->{ $FileTag::K_ParNode };
		if (exists ($parNode->{ $FileTag::K_NodeType })) {
			my $parType = $parNode->{ $FileTag::K_NodeType };
			if ($parType eq "CLASS" || $parType eq "INTERFACE") {
				return $parNode;
			}
			else {
				return $parNode->getCurrNodeUpwardFirstClassOrInterface;
			}
		}
	}
	print __LINE__." getCurrNodeUpwardFirstClassOrInterface failed!\n";
}

sub getJavaPath
{
	my $this = shift;
	if (exists ($this->{ $FileTag::K_ParNode })) {
		my $parNode = $this->{ $FileTag::K_ParNode };
		return $parNode->getJavaPath;
	}
	return $this->{ $FileTag::K_NodeName };
}

sub getFuncInMainClass
{
	my $this = shift;
	my $className = shift;
	my $funcName = shift;
	my $paramsCnt = shift;
	my ($find, $funcNode);
	$find = 0;
	my $mainClass = $this->getMainClassOrInterface;
	if (exists ($mainClass->{ $FileTag::K_SubNodes })) {
		 ($find, $funcNode) = $mainClass->doGetFuncInMainClassLoop($className, $funcName, $paramsCnt);
	}
	return ($find, $funcNode);
}

sub doGetFuncInMainClassLoop
{
	my $this = shift;
	my $className = shift;
	my $funcName = shift;
	my $paramsCnt = shift;
	my ($find, $funcNode);
	$find = 0;
	if (exists ($this->{ $FileTag::K_SubNodes })) {
		my $children = $this->{ $FileTag::K_SubNodes };
		foreach my $child (@$children) {
			if ("CLASS" eq $child->{ $FileTag::K_NodeType } && "INTERFACE" eq $child->{ $FileTag::K_NodeType }) {
				($find, $funcNode) = $child->doGetFuncInMainClassLoop($className, $funcName, $paramsCnt);
				if (1 eq $find) {
					return ($find, $funcNode);
				}
			}
			elsif ("FUNC" eq $child->{ $FileTag::K_NodeType }) {
				if ($funcName eq $child->{ $FileTag::K_NodeName }) {
					my $parms = $child->{ $FileTag::K_Params };
					if ($paramsCnt eq @$parms) {
						return (1, $parms);
					}
				}
			}
		}
	}
	return ($find, $funcNode);
}

sub clear
{
	my $this = shift;
	%$this = {};
}

sub getSubsNodes
{
	my $this = shift;
	if (exists ($this->{ $FileTag::K_SubNodes })) {
		return $this->{ $FileTag::K_SubNodes };
	}

	my @empty;
	$this->{ $FileTag::K_SubNodes } = \@empty;
	return $this->{ $FileTag::K_SubNodes };
}

sub appendChildNode {
	my $this = shift;
	my $node = shift;
	if (!exists ($this->{ $FileTag::K_SubNodes })) {
	    my @childs = ();
	    push @childs, $node;
	    $this->{ $FileTag::K_SubNodes } = \@childs;
	}
	else {
		my $childs = $this->{ $FileTag::K_SubNodes };
		push @$childs, $node;
	}
}

sub insertChildNodeIdx {
	my $this = shift;
	my $idx = shift;
	my $after = shift;
	my $node = shift;
	if (!exists ($this->{ $FileTag::K_SubNodes })) {
	    my @childs = ();
	    $this->{ $FileTag::K_SubNodes } = \@childs;
	}
	else {
		my $childs = $this->{ $FileTag::K_SubNodes };
		if ($idx < 0 || $idx >= @$childs) {
			push @$childs, $node;
		}
		else {
			if (1 eq $after) { ++$idx; }
			splice(@$childs, $idx, 0, $node);
		}
	}
}

sub getCurrNodeIdxInParent {
	my $this = shift;
	my $index = 0;
	my $findOk = 0;
	if ($this->{ $FileTag::K_ParNode }) {
		my $childs = $this->{ $FileTag::K_ParNode }->{ $FileTag::K_SubNodes };
		for (my $idx=0; $idx<@$childs; ++$idx) {
			if ($this->{ $FileTag::K_NodeName } eq $childs->[$idx]->{ $FileTag::K_NodeName }
				&& $this->{ $FileTag::K_SelfData } eq $childs->[$idx]->{ $FileTag::K_SelfData }
				&& $this->{ $FileTag::K_NodeType } eq $childs->[$idx]->{ $FileTag::K_NodeType }
				&& $this->{ $FileTag::K_NodeTag } eq $childs->[$idx]->{ $FileTag::K_NodeTag }) {
				$index = $idx;
				$findOk = 1;
				last;
			}
		}
	}
	return ($findOk, $index);
}

sub getParType
{
	my $this = shift;
	my $par;
	if (exists ($this->{ $FileTag::K_ParNode })) {
	    $par = $this->{ $FileTag::K_ParNode };
	    return $par->{ $FileTag::K_NodeType };
	}
	print __LINE__." getParType ParNode is not exists\n";
}

sub isCurrUpwardInType
{
	my $this = shift;
	my $type = shift;
	if ($this->{ $FileTag::K_NodeType } eq $type) {
		return 1;
	}
	return $this->isUpwardInType($type);
}

sub isUpwardInType
{
	my $this = shift;
	my $type = shift;
	if ($this->{ $FileTag::K_ParNode }) {
		if ($this->{ $FileTag::K_ParNode }->{ $FileTag::K_NodeType } eq $type) {
			return 1;
		}
		else {
			return $this->{ $FileTag::K_ParNode }->isUpwardInType($type);
		}
	}
	else {
		return 0;
	}
}

sub currUpwardInClassOrInterface
{
	my $this = shift;
	if ($this->{ $FileTag::K_NodeType } eq "CLASS" || $this->{ $FileTag::K_NodeType } eq "INTERFACE") {
		return $this->{ $FileTag::K_NodeType };
	}
	if ($this->{ $FileTag::K_ParNode }) {
		return $this->{ $FileTag::K_ParNode }->currUpwardInClassOrInterface;
	}
	return "";
}

sub currScopePath
{
	my $this = shift;
	my @paths = ();
	$this->doScopePath(\@paths);
	my @result = reverse(@paths);
	my $resultPath = join "::", @result;
	return $resultPath;
}

sub doScopePath
{
	my $this = shift;
	my $paths = shift;

	if ($this->{ $FileTag::K_NodeType } eq "CLASS" || $this->{ $FileTag::K_NodeType } eq "INTERFACE") {
		push @$paths, $this->{ $FileTag::K_NodeName };
	}

	if ($this->{ $FileTag::K_ParNode }) {
		return $this->{ $FileTag::K_ParNode }->doScopePath($paths);
	}
	else {
		return $paths;
	}
}

sub lastBrother
{
	my $this = shift;
	my $outBrother;
	my $findOk = 0;
	if ($this->{ $FileTag::K_ParNode }) {
		my $childs = $this->{ $FileTag::K_ParNode }->{ $FileTag::K_SubNodes };
		for (my $idx=0; $idx<@$childs; ++$idx) {
			if ($this->{ $FileTag::K_NodeName } eq $childs->[$idx]->{ $FileTag::K_NodeName }
				&& $this->{ $FileTag::K_SelfData } eq $childs->[$idx]->{ $FileTag::K_SelfData }) {
				--$idx;
				if ($idx >= 0) {
					$findOk = 1;
					$outBrother = $childs->[$idx];
				}
				last;
			}
		}
	}
	return ($findOk, $outBrother);
}

sub parentNode
{
	my $this = shift;
	my $parentNode;
	my $findOk = 0;
	if ($this->{ $FileTag::K_ParNode }) {
		$parentNode = $this->{ $FileTag::K_ParNode };
		$findOk = 1;
	}
	return ($findOk, $parentNode);
}

sub nextBrother
{
	my $this = shift;
	my $outBrother;
	my $findOk = 0;
	if ($this->{ $FileTag::K_ParNode }) {
		my $childs = $this->{ $FileTag::K_ParNode }->{ $FileTag::K_SubNodes };
		for (my $idx=0; $idx<@$childs; ++$idx) {
			if ($this->{ $FileTag::K_NodeName } eq $childs->[$idx]->{ $FileTag::K_NodeName }
				&& $this->{ $FileTag::K_SelfData } eq $childs->[$idx]->{ $FileTag::K_SelfData }) {
				++$idx;
				if ($idx<@$childs) {
					$findOk = 1;
					$outBrother = $childs->[$idx];
				}
				last;
			}
		}
	}
	return ($findOk, $outBrother);
}

sub lastBrotherSpecifyType
{
	my $this = shift;
	my $type = shift;
	my $outBrother;
	my $findOk = 0;
	if ($this->{ $FileTag::K_ParNode }) {
		my $childs = $this->{ $FileTag::K_ParNode }->{ $FileTag::K_SubNodes };
		my @newChilds = grep { $type eq $_->{ $FileTag::K_NodeType } } @$childs;
		for (my $idx=0; $idx<@newChilds; ++$idx) {
			if ($this->{ $FileTag::K_NodeName } eq $newChilds[$idx]->{ $FileTag::K_NodeName }
			 	&& $this->{ $FileTag::K_SelfData } eq $newChilds[$idx]->{ $FileTag::K_SelfData }) {
				--$idx;
				if ($idx >= 0) {
					$findOk = 1;
					$outBrother = $newChilds[$idx];
				}
				last;
			}
		}
	}
	return ($findOk, $outBrother);
}

sub nextBrotherSpecifyType
{
	my $this = shift;
	my $type = shift;
	my $outBrother;
	my $findOk = 0;
	if ($this->{ $FileTag::K_ParNode }) {
		my $childs = $this->{ $FileTag::K_ParNode }->{ $FileTag::K_SubNodes };
		my @newChilds = grep { $type eq $_->{ $FileTag::K_NodeType } } @$childs;
		for (my $idx=0; $idx<@newChilds; ++$idx) {
			if ($this->{ $FileTag::K_NodeName } eq $newChilds[$idx]->{ $FileTag::K_NodeName }) {
				++$idx;
				if ($idx<@newChilds) {
					$findOk = 1;
					$outBrother = $newChilds[$idx];
				}
				last;
			}
		}
	}
	return ($findOk, $outBrother);
}

sub firstChildSpecifyType
{
	my $this = shift;
	my $type = shift;

	my $node;
	my $index = 0;
	my $findOk = 0;

	if (exists ($this->{ $FileTag::K_SubNodes })) {
		my $childs = $this->{ $FileTag::K_SubNodes };
		for (my $idx=0; $idx<@$childs; ++$idx) {
			my $child = $childs->[ $idx ];
			if ($type eq $child->{ $FileTag::K_NodeType }) {
				$findOk = 1;
				$node = $child;
				$index = $idx;
				last;
			}
		}
	}
	return ($findOk, $node, $index);
}

sub allChildrenSpecifyType
{
	my $this = shift;
	my $type = shift;

	my $node;
	my @allChildrenSpecifyType;
	my $index = 0;
	my $findOk = 0;

	if (exists ($this->{ $FileTag::K_SubNodes })) {
		my $childs = $this->{ $FileTag::K_SubNodes };
		for (my $idx=0; $idx<@$childs; ++$idx) {
			my $child = $childs->[ $idx ];
			if ($type eq $child->{ $FileTag::K_NodeType }) {
				$findOk = 1;
				my %eachChild = ();
				$eachChild{ "NODE" } = $child;
				$eachChild{ "INDEX" } = $idx;
				push @allChildrenSpecifyType, \%eachChild;
			}
		}
	}
	return ($findOk, \@allChildrenSpecifyType);
}

sub scopeIsNodeTypeSame
{
	my $this = shift;
	my $type0 = shift;
	my $type1 = shift;
	my $isSame = 0;

	if ($type0 eq $type1) {
		$isSame = 1;
	}
	elsif (1 eq &isNodeTypeIsClassOrInterface($type0) && 1 eq &isNodeTypeIsClassOrInterface($type1)) {
		$isSame = 1;
	}
	elsif (1 eq &isNodeTypeIsVar($type0) && 1 eq &isNodeTypeIsVar($type1)) {
		$isSame = 1;
	}
	elsif (1 eq &isNodeTypeIsFunc($type0) && 1 eq &isNodeTypeIsFunc($type1)) {
		$isSame = 1;
	}
	return $isSame;
}

sub isNodeTypeIsClassOrInterface
{
	my $type = shift;
	if ("CLASS" eq $type || "INTERFACE" eq $type) { return 1; }
	return 0;
}

sub isNodeTypeIsVar
{
	my $type = shift;
	if ("VAR_DEFINE" eq $type || "VAR_ASSIGNMENT" eq $type) { return 1; }
	return 0;
}

sub isNodeTypeIsFunc
{
	my $type = shift;
	if ("FUNC" eq $type) { return 1; }
	return 0;
}

sub isNodeTypeValidUsedInTypeCompareSame
{
	my $this = shift;
	my $type = shift;
	if ("CLASS" eq $type || "INTERFACE" eq $type || "FUNC" eq $type
			|| "VAR_DEFINE" eq $type || "VAR_ASSIGNMENT" eq $type) {
		return 1;
	}
	return 0;
}

sub testOutputStruct
{
	my $this = shift;
	my $startSpace = shift;
	print $startSpace;
	if (exists ($this->{ $FileTag::K_Scope })) { print $this->{ $FileTag::K_Scope }." "; }
	if (exists ($this->{ $FileTag::K_NodeType })) { print $this->{ $FileTag::K_NodeType }." "; }
	if (exists ($this->{ $FileTag::K_NodeName })) { print $this->{ $FileTag::K_NodeName }." "; }
	if (exists ($this->{ $FileTag::K_Return })) { print "[".$this->{ $FileTag::K_Return }."] "; }

	if (exists ($this->{ $FileTag::K_NodeType })) {
		if ("FUNC" eq $this->{ $FileTag::K_NodeType } && exists($this->{ $FileTag::K_Params })) {
			my $params = $this->{ $FileTag::K_Params };
			print "params: ";
			foreach my $item (@$params) {
				print "[$item->{ $FileTag::K_ParamType } => $item->{ $FileTag::K_ParamName }] ";
			}
		}
	}
	print "\n";
	$startSpace = $startSpace."    ";
	if (exists ($this->{ $FileTag::K_InnClassSeq })) {
		my $innerClass = $this->{ $FileTag::K_InnClassSeq };
		foreach my $child (@$innerClass) {
			&testOutputStruct($child, $startSpace);
		}
	}

	if (exists ($this->{ $FileTag::K_SubNodes })) {
		my $children = $this->{ $FileTag::K_SubNodes };
		foreach my $child (@$children) {
			&testOutputStruct($child, $startSpace);
		}
	}
}


1;
