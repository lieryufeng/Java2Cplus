#!/usr/bin/perl;

package ScopeStackManager;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(  );
use strict;
use TransElastosType;
use FileAnalysisStruct;

my @gStackFuncVarStack = ();
my @gStackScopeStartIdxs = ();

sub stackReset
{
	@gStackFuncVarStack = ();
	@gStackScopeStartIdxs = ();
}

sub stackBeginNewScope
{
	my $newStartIdx = @gStackFuncVarStack;
	push @gStackScopeStartIdxs, $newStartIdx;
}

sub stackEndNewScopeAndPopup
{
	if (@gStackScopeStartIdxs eq 0) { return ; }
	my $currStackCnt = @gStackFuncVarStack;
	my $donotNeedStartIdx = pop @gStackScopeStartIdxs;
	my $popCnt = $currStackCnt - $donotNeedStartIdx;
	while ($popCnt-- > 0) { pop @gStackFuncVarStack; }
}

sub stackPushVar
{
	my $varName = shift;
	my $varType = shift;
	my %item = ();
	$item{ $varName } = $varType;
	push @gStackFuncVarStack, \%item;
}

sub stackGetAll
{
	return \@gStackFuncVarStack;
}



my @gGloblaVars = ();
sub globalReset
{
	@gGloblaVars = ();
}

sub globalObtVaribles
{
	my $funcNode = shift;

	if (exists ($funcNode->{ $FileTag::K_Params })) {
		my $params = $funcNode->{ $FileTag::K_Params };
		foreach my $item (@$params) {
			my $name = $item->{ $FileTag::K_ParamName };
			my $type = $item->{ $FileTag::K_ParamType };
			$type = TransElastosType::transComplexParamElastosType($type, 1);
			my %var = ();
			$var{ $name } = $type;
			push @gGloblaVars, \%var;
		}
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
						if ("VAR_DEFINE" eq $childType) {
							my $name = $child->{ $FileTag::K_VarName };
							my $type = $child->{ $FileTag::K_VarType };
							$type = TransElastosType::transComplexVarDefineElastosType($type, 1);
							my %var = ();
							$var{ $name } = $type;
							push @gGloblaVars, \%var;
						}
						if ("VAR_ASSIGNMENT" eq $childType) {
							my $leftNode = $child->{ $FileTag::K_VarAssL };
							my $name = $leftNode->{ $FileTag::K_VarName };
							my $type = $leftNode->{ $FileTag::K_VarType };
							$type = TransElastosType::transComplexVarDefineElastosType($type, 1);
							my %var = ();
							$var{ $name } = $type;
							push @gGloblaVars, \%var;
						}
					}
				}
			}
			$parNode = $parNode->{ $FileTag::K_ParNode };
			$parType = $parNode->{ $FileTag::K_NodeType };
		}
	}
}


sub buildSpecifyVar
{
	my $specifyPrefix = shift;
	my @allVar = ();
	foreach my $item (@gStackFuncVarStack) {
		my @tmpVars = keys %$item;
		push @allVar, @tmpVars;
	}
	@allVar = reverse @allVar;
	foreach my $item (@allVar) {
		if ($item =~ m/^$specifyPrefix/) {
			my $num = substr($item, length($specifyPrefix));
			my $result = "";
			if ("" eq $num) { $result = $specifyPrefix."0"; }
			else {
				++$num;
				$result = "$specifyPrefix".$num;
			}
			return $result;
		}
	}
	return "$specifyPrefix";
}

sub buildTmpVar
{
	my @allVar = ();
	foreach my $item (@gStackFuncVarStack) {
		my @tmpVars = keys %$item;
		push @allVar, @tmpVars;
	}
	@allVar = reverse @allVar;
	foreach my $item (@allVar) {
		if ($item =~ m/^tmp/) {
			my $num = substr($item, length("tmp"));
			my $result = "";
			if ("" eq $num) { $result = "tmp0"; }
			else {
				++$num;
				$result = "tmp".$num;
			}
			return $result;
		}
	}
	return "tmp";
}

sub findVarType
{
	my $var = shift;
	my ($find, $type);
	$find = 0;

	# first find in func var stack
	foreach my $item (@gStackFuncVarStack) {
		if (exists ($item->{ $var })) {
			$type = $item->{ $var };
			$find = 1;
			last;
		}
	}

	# second find in global vars
	foreach my $item (@gGloblaVars) {
		if (exists ($item->{ $var })) {
			$type = $item->{ $var };
			$find = 1;
			last;
		}
	}

	if (0 eq $find) {
		print __LINE__." findVarType: $var cannot find\n";
		<STDIN>;
		return ($find, $type);
	}
	return ($find, $type);
}




1;
