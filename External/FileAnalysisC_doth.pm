#!/usr/bin/perl;

package FileAnalysisC_doth;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;


# input like as: OuterClass/InnerClass/..., first and end letter is not '/',
sub chkClassPathisInDothPath
{
	my $dothPath = shift;
	my $classPathPtr = shift;
	$$classPathPtr = Util::stringTrim($$classPathPtr);
	$$classPathPtr =~ s/^\/\s*//;
	$$classPathPtr =~ s/\s*\/$//;
	my $classPaths = &obtAllClassPathInDoth($dothPath);
	foreach (@$classPaths) {
		if ($_ eq $$classPathPtr) { return 1; }
	}
	return 0;
}

sub obtAllClassPathInDoth
{
	my $dothPath = shift;
	my @classPaths = ();
	my $doc = &analysisC_doth($dothPath);
	my $newClassPath = "";
	&doObtAllClassPathInDoth($doc, \@classPaths, \$newClassPath);
=pod
	print __LINE__." all class path start:\n";
	foreach (@classPaths) {
		print __LINE__." $_\n";
	}
	print __LINE__." all class path end;\n";
=cut
	return \@classPaths;
}

sub doObtAllClassPathInDoth
{
	my $currNode = shift;
	my $classPathsPtr = shift;
	my $classPathPtr = shift;
	my $type = $currNode->{ $FileTag::K_NodeType };
	my $name = $currNode->{ $FileTag::K_NodeName };
	if ("CLASS" eq $type) {
		if ("" eq $$classPathPtr) {
			$$classPathPtr = $name;
		}
		else {
			$$classPathPtr = $$classPathPtr."/".$name;
		}
		push @$classPathsPtr, $$classPathPtr;
	}
	if (exists ($currNode->{ $FileTag::K_SubNodes })) {
		my $children = $currNode->{ $FileTag::K_SubNodes };
		if (@$children > 0) {
			foreach my $item (@$children) {
				my $type = $item->{ $FileTag::K_NodeType };
				if ("CLASS" eq $type) {
					my $newPath = $$classPathPtr;
					&doObtAllClassPathInDoth($item, $classPathsPtr, \$newPath);
				}
				else {
					&doObtAllClassPathInDoth($item, $classPathsPtr, $classPathPtr);
				}
			}
		}
	}
}

sub analysisC_doth
{
	my $dotHPath = shift;
   	my $dotHDataLines = FileOperate::readFile($dotHPath);
   	my $dotHDataContext = join " ", @$dotHDataLines;
   	$dotHDataContext = &removeInvalidContext($dotHDataContext);

    my $doc = createRootNode FileAnalysisStruct($dotHPath);
   	&analysisC_doth_Context($dotHDataContext, $doc);
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

# just analysis class now.
sub analysisC_doth_Context
{
   	my $remainDataContext = shift;
   	my $parNode = shift;

    while (1) {
    	my ($remainDataTmp, $tag, $machSub) = &analysisC_doth_CurrTag($remainDataContext, $parNode);
    	$remainDataContext = $remainDataTmp;
		#my $strTag = FileTag::getTagString($tag);
		#print "--tag=[$strTag], mach_str=[$machSub]\n";
		#sleep 1;
		if (FileTag::isTagValid($tag)) {
			if ($FileTag::DC_class eq $tag) {
				my $newNode = new FileAnalysisStruct;
				$newNode->{ $FileTag::K_NodeTag } = $tag;
				$newNode->{ $FileTag::K_ParNode } = $parNode;
				$parNode->appendChildNode( $newNode );

	    		&analysisC_doth_Class($tag, $machSub, $parNode, $newNode);
	    	}
	    	else {
	    		print __LINE__."[E] \$DC var match failed.\n";
	    	}
		}

    	if ("" eq $remainDataContext) {
    		last;
    	}
    }
}

sub analysisC_doth_Class
{
	my $tag = shift;
	my $machSub = shift;
	my $parNode = shift;
	my $currNode = shift;

    my ($className, @parents);
    $className = "";
    @parents = ();
    my $classDefineDespEndIdx = index($machSub, "{");
    my $classDefineDesp = substr($machSub, 0, $classDefineDespEndIdx);

	# private abstract static class ProfileQuery {
    if ($classDefineDesp =~ m/^class\s+(\S+)/) {
        $className = $1;
    }

	my $maybeParsStartIdx = index($classDefineDesp, ":");
	if ($maybeParsStartIdx > -1) {
		my $parsContent = Util::stringTrim(substr($classDefineDesp, $maybeParsStartIdx + 1));
		my @pars = split(/,/, $parsContent);
		foreach my $item (@pars) {
			my $itemTmp = $item;
			if ($itemTmp =~ m/^\s*public\s*/) { $itemTmp =~ s/^\s*public\s*//; }
			push @parents, $itemTmp;
		}
	}

	# common
	$currNode->{ $FileTag::K_NodeType } = "CLASS";
	$currNode->{ $FileTag::K_NodeName } = $className;
	$currNode->{ $FileTag::K_SelfData } = "";

	# class
	$currNode->{ $FileTag::K_Scope } = "";
	$currNode->{ $FileTag::K_Abstract } = 0;
	$currNode->{ $FileTag::K_Static } = 0;
	$currNode->{ $FileTag::K_Parents } = \@parents;

	my $classEndBracketsIdx = rindex($machSub, "}");
	$machSub = substr($machSub, $classDefineDespEndIdx + 1, $classEndBracketsIdx - 1 - $classDefineDespEndIdx);
	$machSub = Util::stringTrim($machSub);
	if ("" ne $machSub) {
		&analysisC_doth_Context($machSub, $currNode);
	}
}

sub analysisC_doth_CurrTag
{
    my $input = shift;
    my $parNode = shift;
    $input = Util::stringTrim($input);
    #print __LINE__." into analysisC_doth__CurrTag: \$input=$input\n";

    my $inputHasWrap = $input;
    my $inputNoWrap = $input;
    $inputNoWrap =~ s/\r|\n/\t/g;

    my ($stayContent, $tag, $machSub);
    $stayContent = "";
    $tag = -1;
    $machSub = "";
    my $checkOk = 0;
    $tag = $FileTag::DC_unknown;

	if ($inputNoWrap =~ m/class\s+/) {
		$tag = $FileTag::DC_class;
    	$checkOk = 1;

		my $classStartIdx = index($inputNoWrap, "class ");
		my ($isFind, $aimIdx) = Util::findBracketsEnd($inputNoWrap, 2, "->", $classStartIdx);
		$machSub = substr($inputNoWrap, $classStartIdx, $aimIdx - $classStartIdx + 1);
		$stayContent = substr($inputNoWrap, $aimIdx + 1);
	}

	#print __LINE__."[N] CheckCurrTag: \$stayContent=[$stayContent], \$tag=[$tag], \$machSub=[$machSub]\n";
    return ($stayContent, $tag, $machSub);
}


1;