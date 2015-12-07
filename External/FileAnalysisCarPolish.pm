#!/usr/bin/perl;

package FileAnalysisCarPolish;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(  );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;
use BuildMarco;
use BuildNamespace;
use BuildIncludes;


sub polishCar_AnalisisStructs
{
	my $roots = shift;
	my @results = ();
	foreach my $item (@$roots) {
		my $resTmps = &polishCar_AnalisisStruct($item);
		push @results, @$resTmps;
	}
	return \@results;
}

sub polishCar_AnalisisStruct
{
	my $root = shift;
	my @maybeInterfaces = ();
	my $namespace = "";
	&polishCar_InterfaceOutward($root, \@maybeInterfaces, \$namespace);
	return \@maybeInterfaces;
}

=pod
old format:
 	DOC
 		...
 		NAMESPACE
 			NAMESPACE
 				NAMESPACE
 					INTERFACE
 		...

new format
	INTERFACE
		NAMESPACE
		...
		...
=cut
#
sub polishCar_InterfaceOutward
{
	my $root = shift;
	my $maybeInterfaces = shift;
	my $namespacePtr = shift;
	my $rootType = $root->{ $FileTag::K_NodeType };

	if ("DOC" eq $rootType || "MODULE" eq $rootType) {
		my $childs = $root->{ $FileTag::K_SubNodes };
		foreach my $child (@$childs) {
			my $childType = $child->{ $FileTag::K_NodeType };
			#print __LINE__." \$childType=$childType\n";
			if ("NAMESPACE" eq $childType) {
				&polishCar_Namespace($child, $maybeInterfaces, $namespacePtr);
			}
			elsif ("INTERFACE" eq $childType) {
				&polishCar_Interface($child, $maybeInterfaces, $namespacePtr);
			}
			elsif ("DOC" eq $childType || "MODULE" eq $childType) {
				&polishCar_InterfaceOutward($child, $maybeInterfaces, $namespacePtr);
			}
		}
	}
}

sub polishCar_Namespace
{
	my $root = shift;
	my $maybeInterfaces = shift;
	my $namespacePtr = shift;
	#print __LINE__." into polishCar_Namespace: \$\$namespacePtr=[$$namespacePtr]\n";

	my $rootType = $root->{ $FileTag::K_NodeType };
	if ("NAMESPACE" eq $rootType) {
		my $name = $root->{ $FileTag::K_NodeName };
		if ("" eq $$namespacePtr) {
			$$namespacePtr = $name;
		}
		else {
			$$namespacePtr = $$namespacePtr."::".$name;
		}

		#print __LINE__." \$name=$name, \$\$namespacePtr=$$namespacePtr\n";

		my $childs = $root->{ $FileTag::K_SubNodes };
		my $childCnt = @$childs;
		#print __LINE__." \$childCnt=$childCnt\n";
		foreach my $child (@$childs) {
			my $childType = $child->{ $FileTag::K_NodeType };
			#print __LINE__." \$childType=$childType\n";

			if ("NAMESPACE" eq $childType) {
				&polishCar_Namespace($child, $maybeInterfaces, $namespacePtr);
			}
			elsif ("INTERFACE" eq $childType) {
				&polishCar_Interface($child, $maybeInterfaces, $namespacePtr);
			}
		}
	}
}

sub polishCar_Interface
{
	my $root = shift;
	my $maybeInterfaces = shift;
	my $namespacePtr = shift;

	my $interNode = $root->clone;
	$interNode->{ $FileTag::K_NodeType } = "INTERFACE";
	$interNode->{ $FileTag::K_NodeTag } = $FileTag::DC_interface;
	$interNode->{ $FileTag::K_NodeName } = $root->{ $FileTag::K_NodeName };
	$interNode->{ $FileTag::K_Namespace } = $$namespacePtr;
	$interNode->{ $FileTag::K_ParNode } = 0;
	push @$maybeInterfaces, $interNode;
}


1;

