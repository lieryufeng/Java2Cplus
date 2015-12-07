#!/usr/bin/perl;

package FileAnalysisJavaOnlyClass;
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


sub chkClassPathisInJavaPath
{
	my $javaPath = shift;
	my $classPathPtr = shift;
	$$classPathPtr = Util::stringTrim($$classPathPtr);
	$$classPathPtr =~ s/^\/\s*//;
	$$classPathPtr =~ s/\s*\/$//;
	$$classPathPtr =~ s/\./\//;
	$$classPathPtr =~ s/::/\//;
	my $classPaths = &obtAllClassPathInJavaPath($javaPath);
	foreach (@$classPaths) {
		if ($_ eq $$classPathPtr) { return 1; }
	}
	return 0;
}

sub chkClassPathisInJavaFileNode
{
	my $javaNode = shift;
	my $classPathPtr = shift;
	$$classPathPtr = Util::stringTrim($$classPathPtr);
	$$classPathPtr =~ s/^\/\s*//;
	$$classPathPtr =~ s/\s*\/$//;
	$$classPathPtr =~ s/\./\//;
	$$classPathPtr =~ s/::/\//;
	my @classPaths = ();
	my $newClassPath = "";
	&doObtAllClassPathInJavaPath($javaNode, \@classPaths, \$newClassPath);
=pod
	print __LINE__." all class path start: by JavaFileNode, classPathTmp=$$classPathPtr\n";
	foreach (@classPaths) {
		print __LINE__." $_\n";
	}
	print __LINE__." all class path end;\n";
=cut
	foreach (@classPaths) {
		if ($_ eq $$classPathPtr) { return 1; }
	}
	return 0;
}

sub obtAllClassPathInJavaPath
{
	my $javaPath = shift;
	my @classPaths = ();
	my $doc = &analysisFile($javaPath);
	#$doc->testOutputStruct;
	my $newClassPath = "";
	&doObtAllClassPathInJavaPath($doc, \@classPaths, \$newClassPath);
=pod
	print __LINE__." all class path start: \$javaPath=$javaPath\n";
	foreach (@classPaths) {
		print __LINE__." $_\n";
	}
	print __LINE__." all class path end;\n";
=cut
	return \@classPaths;
}

sub doObtAllClassPathInJavaPath
{
	my $currNode = shift;
	my $classPathsPtr = shift;
	my $classPathPtr = shift;
	my $type = $currNode->{ $FileTag::K_NodeType };
	my $name = $currNode->{ $FileTag::K_NodeName };
	if ("CLASS" eq $type || "INTERFACE" eq $type) {
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
				if ("CLASS" eq $type || "INTERFACE" eq $type) {
					my $newPath = $$classPathPtr;
					&doObtAllClassPathInJavaPath($item, $classPathsPtr, \$newPath);
				}
				else {
					&doObtAllClassPathInJavaPath($item, $classPathsPtr, $classPathPtr);
				}
			}
		}
	}
}

sub analysisFile
{
	my $currJavaPath = shift;
	my $testOutput = shift;

    my $doc = createRootNode FileAnalysisStruct($currJavaPath);
	my @packages = ();
	my @imports = ();
   	ToolDealImports::analysisFileImports($currJavaPath, \@packages, \@imports);
   	foreach my $data (@packages) {
   		my $newNode = new FileAnalysisStruct;
		$newNode->{ $FileTag::K_NodeTag } = $FileTag::DC_package;
		$newNode->{ $FileTag::K_ParNode } = $doc;
		$newNode->{ $FileTag::K_NodeType } = "PACKAGE";
		$newNode->{ $FileTag::K_NodeName } = "";
		$newNode->{ $FileTag::K_SelfData } = $data;
		$doc->appendChildNode( $newNode );
   	}
   	foreach my $data (@imports) {
   		my $newNode = new FileAnalysisStruct;
		$newNode->{ $FileTag::K_NodeTag } = $FileTag::DC_import;
		$newNode->{ $FileTag::K_ParNode } = $doc;
		$newNode->{ $FileTag::K_NodeType } = "IMPORT";
		$newNode->{ $FileTag::K_NodeName } = "";
		$newNode->{ $FileTag::K_SelfData } = $data;
		$doc->appendChildNode( $newNode );
   	}

	my $javaDataLines = FileOperate::readFile($currJavaPath);
	my $removeNotes = Util::noteFilter($javaDataLines);
	if (defined($testOutput) && 1 eq $testOutput) {
		my $removeNotesTmp = Util::addNewLineSignArray($removeNotes);
		#FileOperate::writeFile("/home/lieryufeng/self/test.txt", $removeNotesTmp);
		#print __LINE__." output text.txt\n";
		#<STDIN>;
	}
   	&analysisContext($removeNotes, $doc);
   	return $doc;
}

sub analysisContext
{
   	my $removeNotes = shift;
   	my $parNode = shift;

	my $hasNoWrap = join " ", @$removeNotes;
    my $classInfos = &analysisCurrTag($removeNotes);
    my $tag = 0;
    my $currLine = "";
    my @beginSpacesInfo = ();
    my $beginSpace = "";
    foreach my $classInfo (@$classInfos) {
    	$tag = $classInfo->{ "TAG" };
    	$currLine = $classInfo->{ "CURR_LINE" };
    	$beginSpace = Util::getBeginSpaceOfStr($currLine);
    	if ($FileTag::DC_class eq $tag) {
			my $newNode = new FileAnalysisStruct;
			$newNode->{ $FileTag::K_NodeTag } = $tag;

			my %spaceInfo = ();
			$spaceInfo{ "BEGIN_SPACE" } = $beginSpace;
			$spaceInfo{ "NODE" } = $newNode;

			my $parNodeTmp;
			if (&findParentInfo(\@beginSpacesInfo, $beginSpace, \$parNodeTmp) <= 0) {
				$parNodeTmp = $parNode;
			}

			my $className = "";
			if ($currLine =~ m/class\s+(\w+|\d+)/) {
				$className = $1;
			}

			my $classLineStart = index($hasNoWrap, $currLine);
			if ($classLineStart > 0) {
				my $leftBrackIdx = index($hasNoWrap, "{", $classLineStart);
				my $classStartIdx = rindex($hasNoWrap, "class", $leftBrackIdx);
				my $content = substr($hasNoWrap, $classStartIdx, $leftBrackIdx - $classStartIdx - 1);
				&analysisClass($content, $newNode);
			}

			$newNode->{ $FileTag::K_ParNode } = $parNodeTmp;
			$newNode->{ $FileTag::K_NodeType } = "CLASS";
			$newNode->{ $FileTag::K_NodeName } = $className;
			$parNodeTmp->appendChildNode( $newNode );

    		push @beginSpacesInfo, \%spaceInfo;
    	}
    	elsif ($FileTag::DC_interface eq $tag) {
			my $newNode = new FileAnalysisStruct;
			$newNode->{ $FileTag::K_NodeTag } = $tag;

			my %spaceInfo = ();
			$spaceInfo{ "BEGIN_SPACE" } = $beginSpace;
			$spaceInfo{ "NODE" } = $newNode;

			my $parNodeTmp;
			if (&findParentInfo(\@beginSpacesInfo, $beginSpace, \$parNodeTmp) <= 0) {
				$parNodeTmp = $parNode;
			}

			my $className = "";
			if ($currLine !~ m/\@interface\s+(\w+|\d+)/) {
				if ($currLine =~ m/interface\s+(\w+|\d+)/) {
					$className = $1;
				}
			}

			my $classLineStart = index($hasNoWrap, $currLine);
			if ($classLineStart > 0) {
				my $leftBrackIdx = index($hasNoWrap, "{", $classLineStart);
				my $classStartIdx = rindex($hasNoWrap, "interface", $leftBrackIdx);
				my $content = substr($hasNoWrap, $classStartIdx, $leftBrackIdx - $classStartIdx - 1);
				&analysisInterface($content, $newNode);
			}

			$newNode->{ $FileTag::K_ParNode } = $parNodeTmp;
			$newNode->{ $FileTag::K_NodeType } = "INTERFACE";
			$newNode->{ $FileTag::K_NodeName } = $className;
			$parNodeTmp->appendChildNode( $newNode );

    		push @beginSpacesInfo, \%spaceInfo;
    	}
    }
}

sub analysisClass
{
	my $machSub = shift;
	my $currNode = shift;
	$machSub =~ s/^.*?class\s+(\s+)\s+//;

    my @parents = ();
	my $maybeExtendStartIdx = index($machSub, "extends");
	my $maybeImpStartIdx = index($machSub, "implements");
	my $hasExtend = 0;
	my $contExtend;
	my $hasImplement = 0;
	my $contImplement;
	if ($maybeExtendStartIdx < 0) {
		if ($maybeImpStartIdx > 0) {
			my $usefullStart = $maybeImpStartIdx + length("implements");
	        if ($usefullStart > 0) {
	        	$hasImplement = 1;
	            $contImplement = substr($machSub, $usefullStart, (length($machSub)-1 - $usefullStart));
	        }
		}
	}
	else {
		if ($maybeImpStartIdx < 0) {
	        my $usefullStart = $maybeExtendStartIdx + length("extends");
	        if ($usefullStart > 0) {
	        	$hasExtend = 1;
	            $contExtend = substr($machSub, $usefullStart, (length($machSub)-1 - $usefullStart));
				$contExtend = Util::stringTrim($contExtend);
	        }
		}
		else {
			# extends baseClass implements baseInterface0, baseInterface1 ...
			# java just only can be single inherted.
			if ($maybeImpStartIdx > $maybeExtendStartIdx) {
				my $extUsefullStart = $maybeExtendStartIdx + length("extends");
				$hasExtend = 1;
				$contExtend = substr($machSub, $extUsefullStart, $maybeImpStartIdx - $extUsefullStart);
				$contExtend = Util::stringTrim($contExtend);

				my $impUsefullStart = $maybeImpStartIdx + length("implements");
		        if ($impUsefullStart > 0) {
		        	$hasImplement = 1;
		            $contImplement = substr($machSub, $impUsefullStart, (length($machSub)-1 - $impUsefullStart));
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

	# class
	$currNode->{ $FileTag::K_Scope } = "";
	$currNode->{ $FileTag::K_Abstract } = 0;
	$currNode->{ $FileTag::K_Static } = 0;
	$currNode->{ $FileTag::K_Parents } = \@parents;
}

sub analysisInterface
{
	my $machSub = shift;
	my $currNode = shift;
	$machSub =~ s/^.*?interface\s+(\s+)\s+//;

    my @parents = ();
    my $maybeImpStartIdx = index($machSub, "implements");
	my $hasImplement = 0;
	my $contImplement;

	if ($maybeImpStartIdx > 0) {
		my $usefullStart = $maybeImpStartIdx + length("implements");
        if ($usefullStart > 0) {
        	$hasImplement = 1;
            $contImplement = substr($machSub, $usefullStart, (length($machSub)-1 - $usefullStart));
        }
	}

	if (1 eq $hasImplement) {
		my @parentsTemp = split(/,/, $contImplement);
		@parentsTemp = &StringTrimArray(@parentsTemp);
	    push (@parents, @parentsTemp);
	}

	# class
	$currNode->{ $FileTag::K_Scope } = "";
	$currNode->{ $FileTag::K_Abstract } = 0;
	$currNode->{ $FileTag::K_Static } = 0;
	$currNode->{ $FileTag::K_Parents } = \@parents;
}

# just use java code format to check parent and child info
# donot check symbol left and right mach
# this method may analysis wrong item but has no error
sub analysisCurrTag
{
    my $inputs = shift;
	my @results = ();
	foreach my $line (@$inputs) {
		if ($line =~ m/\s*class\s+(\S+)/ && $line !~ m/(\"|\').*?class\s+/) {
			my %item = ();
			$item{ "TAG" } = $FileTag::DC_class;
			$item{ "CURR_LINE" } = $line;
			push @results, \%item;
		}
		elsif ($line =~ m/\s*interface\s+/ && $line !~ m/\@interface/ && $line !~ m/(\"|\').*?interface\s+/) {
			my %item = ();
			$item{ "TAG" } = $FileTag::DC_interface;
			$item{ "CURR_LINE" } = $line;
			push @results, \%item;
		}
	}
    return \@results;
}


=pod
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
		}
	}

	# 2: check note specify invalid content
	# is note? note is invalid content
	if (0 eq $checkOk) {
		if ($inputNoWrap =~ m/^(\/\*.*?\*\/)/g) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	&analysisCurrTag($stayContent, $parNode);
	    }
	    # elsif ($inputHasWrap =~ m/^(\/\/.*)$/) {
	    elsif ($inputHasWrap =~ m/^(\/\/.*)/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	&analysisCurrTag($stayContent, $parNode);
	    }
	}

	# 3: check begin with @(specify invalid content)
	#  and  check specify format that start with "package" or "import"
	if (0 eq $checkOk) {
		if ($inputHasWrap =~ m/^(@.*?)\n/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	&analysisCurrTag($stayContent, $parNode);
	    }
	    elsif ($inputHasWrap =~ m/^(package\s+.*?)\n/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	&analysisCurrTag($stayContent, $parNode);
	    }
	    elsif ($inputHasWrap =~ m/^(import\s+.*?)\n/) {
	    	$machSub = substr($inputHasWrap, 0, length($1));
	    	$stayContent = substr($inputHasWrap, length($1));
	    	&analysisCurrTag($stayContent, $parNode);
	    }
	}

	#print __LINE__." \$firstSemicIdx=$firstSemicIdx, \$firstBracketIdx=$firstBracketIdx\n";
	#if (-1 eq $firstSemicIdx && -1 eq $firstBracketIdx) {
	#	print __LINE__." \$inputHasWrap=$inputHasWrap\n";
	#}
	# 4: check end with ";" or "};" or ");"
	if (0 == $checkOk) {
		my ($endSymbol, $endSymIdx) = Util::obtEndSymbol($inputHasWrap);
		print __LINE__." analysisCurrTag: \$endSymbol=$endSymbol, \$endSymIdx=$endSymIdx\n";
		<STDIN>;

		if (";" eq $endSymbol) {
			$machSub = substr($inputHasWrap, 0, $endSymIdx+1);
			$stayContent = substr($inputHasWrap, $endSymIdx+1);
			&analysisCurrTag($stayContent, $parNode);
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
				<STDIN>;
			}

			my $firstSemicIdx = index($inputHasWrap, ";");
			my $firstSmallBracketIdx = index($inputHasWrap, "(");
			my $firstBigBracketIdx = index($inputHasWrap, "{");
			my $leftBracketsSub = substr($inputHasWrap, 0, $firstBigBracketIdx);
			if ($leftBracketsSub =~ m/class\s+/) {
				$tag = $FileTag::DC_class;
		    	$checkOk = 1;
			}
			elsif ($leftBracketsSub =~ m/interface\s+/) {
				$tag = $FileTag::DC_interface;
		    	$checkOk = 1;
			}
			else {
				&analysisCurrTag($stayContent, $parNode);
			}
		}
	}

	#print __LINE__." CheckMachIdx=$checkMachIdx\n";

	# all else
	if (0 eq $checkOk) {
		$tag = $FileTag::DC_unknown;
		print __LINE__."[E] \$input=[$input] CheckCurrTag no match, failed. \n";
		#<STDIN>;
	}

	#print __LINE__."[N] CheckCurrTag: \$stayContent=[$stayContent], \$tag=[$tag], \$machSub=[$machSub]\n";
    return ($stayContent, $tag, $machSub);
}
=cut

=pod
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
				print __LINE__."[E] [$inputHasWrap] find brackets end failed.\n";
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
=cut


sub findParentInfo
{
	my $spaceInfos = shift;
	my $currBeginSpace = shift;
	my $aimNodePtr = shift;
	if (@$spaceInfos == 0) {
		return -1;
	}
	my @tmps = reverse @$spaceInfos;
	my $currSpaceLen = length($currBeginSpace);
	my $spaceLenTmp = 0;
	foreach my $item (@tmps) {
		$spaceLenTmp = length($item->{ "BEGIN_SPACE" });
		if ($spaceLenTmp < $currSpaceLen) {
			$$aimNodePtr = $item->{ "NODE" };
			return 1;
		}
	}
	return 0;
}


1;