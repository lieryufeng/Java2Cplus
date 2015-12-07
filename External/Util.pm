#!/usr/bin/perl;

package Util;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
use strict;
use warnings;


# input: $input
# return: $input
sub stringTrim
{
    my $input = shift;
    $input =~ s/^\s+|\s+$//g;
    return $input;
}

# input: $input
# return: $input
sub stringTrimFirstEndEmptyLine
{
    my $input = shift;
    $input =~ s/\s*?$//g;
    $input =~ s/^\s*?\n//g;
    return $input;
}

# input: $input
# return: $input
sub stringTrimArray
{
    my @input = @_;
    for (my $i=0; $i<=$#input; ++$i)
	{
		my $item = $input[$i];
		$item =~ s/^\s+|\s+$//g;
    	$input[$i] = $item;
	}
    return @input;
}

# only trim end of string
sub stringEndTrim
{
	my $input = shift;
    $input =~ s/\s+$//g;
    return $input;
}

# input: $input, $trimBeginStr
# only trim end of specify string
sub stringBeginTrimStr
{
	my $input = shift;
	my $trimBeginStr = shift;
    $input =~ s/^$trimBeginStr//;
    return $input;
}


# input: $input, $trimEndStr
# only trim end of specify string
sub stringEndTrimStr
{
	my $input = shift;
	my $trimEndStr = shift;
    $input =~ s/$trimEndStr$//;
    return $input;
}

# input:
# $direct: =="->" left to right, =="<-" right to left
# $machIdx: n mached, which idx is need. start with 0.
# $aimAfter: $machStr maybe length equal 10, ==1 means idx is $machStr start + length($machStr)
#   			and ==0 means idx is startidx.
sub stringMoreStrSplice
{
	my $oldStr = shift;
	my $insStr = shift;
	my $machStr = shift;
	my $direct = shift;
	my $machIdx = shift;
	my $aimAfter = shift;
	my $offset = shift;
	my $overCnt = shift;

	if ("" eq $oldStr) {
		return -1;
	}

	my @searchIdxs = ();
	my $startIdx = 0;
	my $searchIdx = -1;
	while (($searchIdx = index($oldStr, $machStr, $startIdx)) >= 0) {
		push @searchIdxs, $searchIdx;
		$startIdx = $searchIdx + length($machStr);
	}
	if ($#searchIdxs < 0) {
		return -1;
	}

	$machIdx = $machIdx < 0 ? 0 : $machIdx;
	$machIdx = $machIdx > $#searchIdxs ? $#searchIdxs : $machIdx;
	my $aimMachIdx = -1;
	if ("<-" eq $direct) {
		my @tmps = reverse(@searchIdxs);
		$aimMachIdx = $tmps[$machIdx];
	}
	else {
		$aimMachIdx = $searchIdxs[$machIdx];
	}

	if (1 eq $aimAfter) {
		$aimMachIdx += length($machStr);
	}

	$aimMachIdx += $offset;
	return &stringSplice($oldStr, $aimMachIdx, $overCnt, $insStr);
}

sub stringMoreRegSplice
{
	my $oldStr = shift;
	my $insStr = shift;
	my $machReg = shift;
	my $direct = shift;
	my $machIdx = shift;
	my $aimAfter = shift;
	my $offset = shift;
	my $overCnt = shift;

	if ("" eq $oldStr) {
		return -1;
	}

	my @machInfos = ();
	my $startIdx = 0;
	my $searchIdx = -1;
	while ($oldStr =~ m/($machReg)/g) {
		my $mach = $1;
		$searchIdx = index($oldStr, $mach, $startIdx);
		my %machInfo;
		$machInfo{ "IDX" } = $searchIdx;
		$machInfo{ "MACH" } = $mach;
		push @machInfos, \%machInfo;
		# regular is not same to string, it may mach more at curr idx,
		# but the choice of > once remain stay curr idx is relatively small, so add 1 here.
		$startIdx = $searchIdx + 1;
	}
	if ($#machInfos < 0) {
		return -1;
	}

	$machIdx = $machIdx < 0 ? 0 : $machIdx;
	$machIdx = $machIdx > $#machInfos ? $#machInfos : $machIdx;

	my $aimMachInfo;
	if ("<-" eq $direct) {
		my @tmps = reverse(@machInfos);
		$aimMachInfo = $tmps[$machIdx];
	}
	else {
		$aimMachInfo = $machInfos[$machIdx];
	}

	my $aimMachIdx = $aimMachInfo->{ "IDX" };
	my $machStr = $aimMachInfo->{ "MACH" };
	if (1 eq $aimAfter) {
		$aimMachIdx += length($machStr);
	}
	if ($overCnt < 0) {
		$overCnt = length($machStr);
	}

	$aimMachIdx += $offset;
	return &stringSplice($oldStr, $aimMachIdx, $overCnt, $insStr);
}

sub stringSplice
{
	my $oldStr = shift;
	my $startIdx = shift;
	my $overCnt = shift;
	my $insStr = shift;
	my $sub0 = substr($oldStr, 0, $startIdx);
	my $sub1;
	$overCnt = $overCnt < 0 ? 0 : $overCnt;
	$sub1 = substr($oldStr, $startIdx + $overCnt);
	my $result = $sub0.$insStr.$sub1;
	return $result;
}

sub stringSpliceReplace
{
	my $oldStr = shift;
	my $startIdx = shift;
	my $overCnt = shift;
	my $replace = shift;
	my $sub0 = substr($oldStr, 0, $startIdx);
	my $sub1;
	$overCnt = $overCnt < 0 ? 0 : $overCnt;
	$sub1 = substr($oldStr, $startIdx + $overCnt);
	my $replaceStr = "";
	while ($overCnt-- > 0) {
		$replaceStr = $replaceStr.$replace;
	}
	my $result = $sub0.$replaceStr.$sub1;
	return $result;
}

sub stringSpliceRegReplace
{
	my $oldStr = shift;
	my $startIdx = shift;
	my $overCnt = shift;
	my $reg = shift;
	my $replace = shift;
	my $sub0 = substr($oldStr, 0, $startIdx);
	my $sub1 = substr($oldStr, $startIdx + $overCnt);
	my $replaceStr = substr($oldStr, $startIdx, $overCnt);
	$replaceStr =~ s/\S/ /g;
	my $result = $sub0.$replaceStr.$sub1;
	return $result;
}

sub stringSplitParamsContent
{
	my $oldStr = shift;
	my $splitSign = ",";
	my @donotInPairs = ();
	{
		my %pair = ();
		$pair{ "FIRST" } = "(";
		$pair{ "SECOND" } = ")";
		push @donotInPairs, \%pair;
	}
	{
		my %pair = ();
		$pair{ "FIRST" } = "[";
		$pair{ "SECOND" } = "]";
		push @donotInPairs, \%pair;
	}
	{
		my %pair = ();
		$pair{ "FIRST" } = "{";
		$pair{ "SECOND" } = "}";
		push @donotInPairs, \%pair;
	}
	{
		my %pair = ();
		$pair{ "FIRST" } = "<";
		$pair{ "SECOND" } = ">";
		push @donotInPairs, \%pair;
	}
	return &stringSplitMoreMach($oldStr, $splitSign, \@donotInPairs);
}

sub stringSplitFuncContinueCallContent
{
	my $oldStr = shift;
	my $splitSign = ".";
	my @donotInPairs = ();
	{
		my %pair = ();
		$pair{ "FIRST" } = "(";
		$pair{ "SECOND" } = ")";
		push @donotInPairs, \%pair;
	}
	{
		my %pair = ();
		$pair{ "FIRST" } = "[";
		$pair{ "SECOND" } = "]";
		push @donotInPairs, \%pair;
	}
	{
		my %pair = ();
		$pair{ "FIRST" } = "{";
		$pair{ "SECOND" } = "}";
		push @donotInPairs, \%pair;
	}
	{
		my %pair = ();
		$pair{ "FIRST" } = "<";
		$pair{ "SECOND" } = ">";
		push @donotInPairs, \%pair;
	}
	return &stringSplitMoreMach($oldStr, $splitSign, \@donotInPairs);
}

sub stringSplitMoreMach
{
	my $oldStr = shift;
	my $splitSign = shift;
	my $donotInPairs = shift;
	$oldStr = Util::stringTrim($oldStr);
	my @splitRes = ();
	my $offset = 0;
	while ("" ne $oldStr) {
		my $oldTmp = substr($oldStr, $offset);
		if ($oldTmp =~ m/^\s*$splitSign/) {
			push @splitRes, Util::stringTrim(substr($oldStr, 0, $offset));
			$oldStr = Util::stringTrim($oldTmp);
			last if ("" eq $oldStr);
			$offset = 0;
		}

		my $splitSignIdx = index($oldStr, $splitSign, $offset);
		my %pirFirstIdxInfos = ();
		foreach my $eachPair (@$donotInPairs) {
			my $idxTmp = index($oldStr, $eachPair->{ "FIRST" }, $offset);
			$pirFirstIdxInfos{ $idxTmp } = $eachPair;
		}

		my @pirFirstIdxs = keys %pirFirstIdxInfos;
		my ($find, $mindata) = &usefullMin(\@pirFirstIdxs, -1);
		if (1 eq $find) {
			if ($splitSignIdx < $mindata) {
				my $tmp = substr($oldStr, 0, $splitSignIdx);
				push @splitRes, $tmp;
				$oldStr = substr($oldStr, $splitSignIdx+1);
				$offset = 0;
			}
			else {
				my $minFirstSym = $pirFirstIdxInfos{ $mindata }->{ "FIRST" };
				my $bracketsType = 0;
				if ("(" eq $minFirstSym) { $bracketsType = 0; }
				elsif ("[" eq $minFirstSym) { $bracketsType = 1; }
				elsif ("{" eq $minFirstSym) { $bracketsType = 2; }
				elsif ("<" eq $minFirstSym) { $bracketsType = 3; }
				else { die __LINE__." stringSplitMoreMach: no mach bracktype\n"; }
				my ($isFind, $aimIdx) = &findBracketsEnd($oldStr, $bracketsType, "->", $offset);
				if (0 eq $isFind) { die __LINE__." stringSplitMoreMach: findBracketsEnd ret find=0\n"; }
				$offset = $aimIdx + 1;
			}
		}
		else {
			$oldStr =~ s/^\s*$splitSign\s*//;
			push @splitRes, $oldStr;
			last;
		}
	}
	return \@splitRes;
}

sub stringArrayFormatLine
{
	my $array = shift;
	my $space = shift;
	my @result = ();
	my $retainSpaceCnt = length($space);
	my $minSpaceCnt = 100;
	my $beginSpace;
	my $spaceLength;

	foreach my $item (@$array) {
		next if ($item =~ m/^\s*$/);
		$beginSpace = &getBeginSpaceOfStr($item);
		if ("" eq $beginSpace) { $spaceLength = 0; }
		else { $spaceLength = length($beginSpace); }
		$minSpaceCnt = $minSpaceCnt > $spaceLength ? $spaceLength : $minSpaceCnt;
	}

	my $addSpace = $retainSpaceCnt - $minSpaceCnt;
	#print __LINE__." \$minSpaceCnt=$minSpaceCnt, \$addSpace=$addSpace\n";
	my $arrCnt = @$array;
	if ($addSpace > 0) {
		my $appendSpace;
		while ($addSpace-- > 0) { $appendSpace = $appendSpace." "; }
		my $tmp;
		foreach my $item (@$array) {
			if ($item =~ m/^\s*$/) {
				$tmp = "";
			}
			else {
				$tmp = $appendSpace.$item;
			}
			push @result, $tmp;
		}
	}
	elsif ($addSpace < 0) {
		my $appendSpace;
		while ($addSpace++ < 0) { $appendSpace = $appendSpace." "; }
		my $tmp;
		foreach my $item (@$array) {
			if ($item =~ m/^\s*$/) {
				$tmp = "";
			}
			else {
				$tmp = &stringBeginTrimStr($item, $appendSpace);
			}
			push @result, $tmp;
		}
	}
	else {
		@result = @$array;
	}

=pod
	print __LINE__." after format show shart\n";
	foreach (@result) {
		print $_."\n";
	}
	print __LINE__." after format show end\n";
=cut

	return \@result;
}

sub ucfirstArray
{
	my $inputArrars = shift;
	my @result = ();
	foreach (@$inputArrars) {
		push @result, ucfirst($_);
	}
	return \@result;
}

sub addNewLineSignArray
{
	my $inputArrars = shift;
	my @result = ();
	foreach (@$inputArrars) {
		push @result, ucfirst($_."\n");
	}
	return \@result;
}

sub commitOutArray
{
	my $inputArrars = shift;
	my @result = ();
	foreach (@$inputArrars) {
		if ($_ eq "") { push @result, "//".$_; }
		else { push @result, "// ".$_; }
	}
	return \@result;
}

sub toLowerArray
{
	my $inputArrars = shift;
	my @result = ();
	foreach my $item (@$inputArrars) {
		$item =~ tr/[A-Z]/[a-z]/;
		push @result, $item;
	}
	return \@result;
}

# input: $filePath, @fileData
# return: .cpp file name
sub readFile
{
    my $input = shift;
	open (FILE, "<", $input) || die "can not open file $input.\n";
	my @fileData = <FILE>;
	close FILE;
	return \@fileData;
}

# input: $filePath, @fileData
# return: .cpp file name
sub writeFile
{
    my $input = shift;
    my $fileData = shift;
	open (FILE, ">", $input);
	print FILE (@$fileData);
	close FILE;
}

# input: $fileHandle, $tabStartCount
# note: one tab equal four space
sub writeTab
{
	my $fileHandle = shift;
	my $tabStartCount = shift;
	my $eachTab = "    ";
	for (my $i=0; $i<$tabStartCount; ++$i)
	{
		print ($fileHandle, $eachTab);
	}
}

sub arraySplice
{
	my $srcArray = shift;
	my $startIdx = shift;
	my $count = shift;
	if (!defined($count)) {
		$count = @$srcArray;
	}
	my @result = ();
	for (my $idx=0; $idx<@$srcArray; ++$idx) {
		if ($idx >= $startIdx) {
			if ($count-- > 0) {
				push @result, $srcArray->[ $idx ];
			}
			else {
				last;
			}
		}
	}
	return \@result;
}

sub arraySwap
{
	my $srcArray = shift;
	my $firstIdx = shift;
	my $secondIdx = shift;
	if ($firstIdx >= 0 && $firstIdx < @$srcArray && $secondIdx >= 0 && $secondIdx < @$srcArray) {
		my $temp = $srcArray->[$firstIdx];
		$srcArray->[$firstIdx] = $srcArray->[$secondIdx];
		$srcArray->[$secondIdx] = $temp;
	}
}

# input: $input
# return: the the beginning space of a string
sub getBeginSpaceOfStr
{
	my $input = shift;
	my $ret = "";
	if ($input =~ m/^(\s+)/)
	{
		$ret = $1;
	}
	return $ret;
}

sub getFileNameByPath
{
	my $path = shift;
	my $endSlashIdx = rindex($path, "/");
	return substr($path, $endSlashIdx+1);
}

sub getFileNameNoEndPrefixByPath
{
	my $path = shift;
	my $buf = &getFileNameByPath($path);
	if ($buf =~ m/\./) {
		$buf =~ s/\.(\w|\d)*$//;
	}
	return $buf;
}

sub getSplitSubStr
{
	my $input = shift;
	my $split = shift;
	my $index = shift;
	my @subs = split($split, $input);
	my $tmpStr = join ", ", @subs;
	#print __LINE__." getSplitSubStr: \$input=$input, \$tmpStr=[$tmpStr]\n";
	if ($index < 0) { $index = $#subs; }
	elsif ($index >= @subs) { $index = $#subs; }
	if (@subs > 0) {
		return $subs[$index];
	}
	return "";
}

# input: $srcType
# return: $dstType
sub addAutoPtrSign
{
	my $srcType = shift;
	my $dstType;
	if ($srcType =~ m/>$/)
	{
		$dstType = "AutoPtr< $srcType >";
	}
	else
	{
		$dstType = "AutoPtr<$srcType>";
	}
	return $dstType;
}

sub addCARAPI_Sign
{
	my $srcType = shift;
	return "CARAPI_($srcType)";;
}

sub addSpecifySignLikeAutoPtr
{
	my $srcType = shift;
	my $sign = shift;
	my $dstType;
	if ($srcType =~ m/>$/)
	{
		$dstType = "$sign< $srcType >";
	}
	else
	{
		$dstType = "$sign<$srcType>";
	}
	return $dstType;
}

sub rmSignLikeAutoPtr
{
	my $srcType = shift;
	my $sign = shift;

	$srcType = Util::stringTrim($srcType);
	my $dstType = $srcType;
	if ($srcType =~ m/^$sign\s*</) {
		$srcType =~ s/^$sign\s*<//;
		$srcType =~ s/>$//;
	}
	return $dstType;
}

sub isNextUsefullStr
{
	my $src = shift;
	my $specify = shift;
	my $offset = shift;
	$offset = $offset < 0 ? 0 : $offset;
	my $newSrc = substr($src, $offset);
	$newSrc = &stringTrim($newSrc);
	if ($newSrc =~ m/^$specify/g) {
		return 1;
	}
	return 0;
}

sub isOneOfArray
{
	my $array = shift;
	my $value = shift;
	my @tmps = grep { $_ eq $value } @$array;
	if (@tmps > 0) { return 1; }
	return 0;
}

sub isStrFirstUpper
{
	my $input = shift;
	my $tmp = ucfirst($input);
	if ($tmp eq $input) { return 1; }
	return 0;
}

sub isStrUpper
{
	my $input = shift;
	my $tmp = $input;
	$tmp =~ tr/[a-z]/[A-Z]/;
	if ($tmp eq $input) { return 1; }
	return 0;
}

sub noteFilter
{
	my $arrays = shift;
	my @arrayTmps = ();
	my $tmp = "";
	my $idxTmp = 0;
	foreach my $item (@$arrays) {
		$tmp = $item;
		if ($tmp =~ m/\/\//) {
			$idxTmp = index($tmp, "//");
			$tmp = Util::stringTrim(substr($tmp, 0, $idxTmp));
			if ("" ne $tmp) { push @arrayTmps, $tmp; }
		}
		else { push @arrayTmps, $item; }
	}
	my $arrayStr = join "\t", @arrayTmps;
	$arrayStr =~ s/\n|\r/\t/g;
	while ($arrayStr =~ m/\/\*/g) {
		$arrayStr =~ s/\/\*.*?\*\///g;
	}
	@arrayTmps = split(/\t/, $arrayStr);

	my @arrayTmps1 = ();
	foreach my $item (@arrayTmps) {
		if ($item !~ m/^\s*$/) { push @arrayTmps1, $item; }
	}
	return \@arrayTmps1;
}

sub min
{
	my $sub0 = shift;
	my $sub1 = shift;
	return ($sub0 < $sub1 ? $sub0 : $sub1);
}

sub minArray
{
	my $subs = shift;
	if (0 eq @$subs) { return; }
	my $minVal = $subs->[0];
	foreach (@$subs) {
		$minVal = &min($minVal, $_);
	}
	return $minVal;
}

sub usefullMin
{
	my $array = shift; # numbers
	my $invalidData = shift;
	my ($find, $mindata);
	$find = 0;
	$mindata = -100;

	my @newArray = grep { $_ ne -1 } @$array;
	if (@newArray > 0) {
		$find = 1;
		$mindata = $newArray[0];
		foreach my $item (@newArray) {
			$mindata = &min($mindata, $item);
		}
		return ($find, $mindata);
	}
	return ($find, $mindata);
}

# return: $result
sub obtEndSymbol
{
	my $src = shift;
	my ($result, $endIdx);
	$result = "";
	$endIdx = 0;

	#my $srcTmp = Util::fmtEndSignForJava($src);
	#print __LINE__." after_fmtEndSignForJava: \$srcTmp=\n$srcTmp\n";
	my @specifySyms = qw/; {/;
	my ($find, $firstSym, $symIdx) = &obtFirstSymbolBySpecify($src, \@specifySyms);
	if (1 eq $find) {
		if (";" eq $firstSym) {
			$result = ";";
			$endIdx = $symIdx;
		}
		elsif ("{" eq $firstSym) {
			my ($bigBracketEndFind, $firstBigBracketEndIdx) = Util::findBracketsEnd($src, 2, "->", $symIdx);
			if (1 eq $bigBracketEndFind)	 {
				my $tmp = substr($src, $firstBigBracketEndIdx + 1);
				if ($tmp =~ m/^\s*?;/) {
					$result = ";";
					$endIdx = index($src, ";", $firstBigBracketEndIdx + 1);
				}
				else {
					$result = "}";
					$endIdx = $firstBigBracketEndIdx;
				}
			}
			else {
				my $tmp = substr($src, $firstBigBracketEndIdx);
				print __LINE__." {} donot match, check it:\n";
			}
		}
		else {
			print __LINE__." obtEndSymbol donot match, check it\n";
		}
	}

	return ($result, $endIdx);
}

# return: $result
# ==0: end with ";"
# ==1: end with "{"
# ==2: end with "="
# ==3: end with "("
sub obtFirstSymbol
{
	my $src = shift;
	my ($result, $resIndex);
	$result = -1;
	$resIndex = 0;

	my %gEndWithSymbol = (
		0 => ";",
		1 => "{",
		2 => "=",
		3 => "("
	);

	my $firstSemicIdx = index($src, ";");
	my $firstBigBracketIdx = index($src, "{");
	my $firstEqualIdx = index($src, "=");
	my $firstSmallBracketIdx = index($src, "(");
	my @vals;
	push @vals, $firstSemicIdx;
	push @vals, $firstSmallBracketIdx;
	push @vals, $firstBigBracketIdx;
	push @vals, $firstEqualIdx;

	my $minVal = Util::minArray(\@vals);
	my $index = grep { $vals[$_] eq $minVal } 0..$#vals;
	$result = $gEndWithSymbol{ $index };
	$resIndex = $vals[$index];
	return ($result, $resIndex);
}

sub obtFirstSymbolBySpecify
{
	my $src = shift;
	my $specifies = shift;

	my ($find, $result, $resIndex);
	$find = 0;
	$result = "";
	$resIndex = 0;

	my %hFirstWithSymbol = ();
	my @indexs = ();
	my $haIdx = 0;
	foreach my $item (@$specifies) {
		$hFirstWithSymbol{ $haIdx } = $item;
		++$haIdx;
		push @indexs, index($src, $item);
	}

	if (@indexs > 0) {
		my ($minfind, $minVal) = Util::usefullMin(\@indexs);
		if (1 eq $minfind) {
			$find = 1;
			my $tmpIdx = 0;
			my $index = 0;
			foreach (@indexs) {
				if ($minVal eq $_) {
					$index = $tmpIdx;
				}
				++$tmpIdx;
			}
			$result = $hFirstWithSymbol{ $index };
			#if (!defined($result)) {
				#print __LINE__." \$index=$index, \$minVal=$minVal, \$src=\n$src\n";
				#my $tmpss = 0;
				#foreach (@$specifies) {
				#	print $_." ".$indexs[ $tmpss++ ]." ";
				#}
			#}
			$resIndex = $indexs[$index];
		}

	}

	return ($find, $result, $resIndex);
}

# input: $className
# return: @notes
sub buildCppClassNote
{
	my $className = shift;
	my @notes;
	my $block = "//=====================================================================\n";
	my $blockLength = length($block);
	my $classNameLength = length($className);
	my $classNameStartCnt = ($blockLength - $classNameLength) / 2 - length("//");
	my $space;
	while ($classNameStartCnt-- >= 0) {
		$space = $space." ";
	}
	my $tmp = "//".$space.$className."\n";
	push (@notes, $block);
	push (@notes, $tmp);
	push (@notes, $block);
	my $noteLine = join "\n", &stringTrimArray(@notes);
	return $noteLine;
}

sub splitComplexDataType
{
	my $src = shift;
	my $srcTmp = &stringTrim($src);
	my @subs;
	my $mach = "";
	my $nextBegin = "";
	while ("" ne $srcTmp) {
		$mach = "";
		if ($srcTmp =~ m/^\w+\s*?</) {
			my ($isFind, $endIdx) = &findBracketsEnd($srcTmp, 3);
			$mach = substr($srcTmp, 0, $endIdx + 1);
			$nextBegin = substr($srcTmp, $endIdx + 1);
		}
		elsif ($srcTmp =~ m/^(\w+)\s*?\[/) {
			my ($isFind, $endIdx) = &findBracketsEnd($srcTmp, 1);
			$mach = substr($srcTmp, 0, $endIdx + 1);
			$nextBegin = substr($srcTmp, $endIdx + 1);
			if ($nextBegin =~ m/^\s*\[/) {
				($isFind, $endIdx) = &findBracketsEnd($nextBegin, 1);
				my $subMach = substr($nextBegin, 0, $endIdx + 1);
				$mach = $mach.$subMach;
				$nextBegin = substr($nextBegin, $endIdx + 1);
			}
		}
		elsif ($srcTmp =~ m/^(\w+)\s*,/) {
			$mach = $1;
			my $commaIdx = index($srcTmp, ",");
			$nextBegin = substr($srcTmp, $commaIdx + 1);
		}
		# special user format
		elsif ($srcTmp =~ m/^(\w+\*)/) {
			$mach = $1;
			$nextBegin = substr($srcTmp, length($mach));
		}
		elsif ($srcTmp =~ m/^(\w+\.\w+){1,}$/) {
			$mach = $srcTmp;
			$nextBegin = "";
		}
		elsif ($srcTmp =~ m/^(\w+\s*)/) {
			$mach = $1;
			$nextBegin = substr($srcTmp, length($mach));
		}
		else {
			$mach = $srcTmp;
			$nextBegin = substr($srcTmp, length($mach));
		}

		if ("" ne $mach) {
			$srcTmp = $nextBegin;
			push @subs, &stringTrim($mach);
		}
		$srcTmp = &stringTrim($srcTmp);
	}

	return \@subs;
}

sub splitParamsDespLine
{
	my $src = shift;
	my $srcTmp = &stringTrim($src);
	my @subs;
	my $tmp;
	my $mach = "";
	my $nextBegin = "";
	while ("" ne $srcTmp) {
		if ($srcTmp =~ m/^\w+\s*?</) {
			my ($isFind, $endIdx) = &findBracketsEnd($srcTmp, 3);
			$mach = substr($srcTmp, 0, $endIdx + 1);
			$nextBegin = substr($srcTmp, $endIdx + 1);
			$tmp = $tmp." $mach";
		}
		elsif ($srcTmp =~ m/^(\w+)\s*?\[/) {
			my ($isFind, $endIdx) = &findBracketsEnd($srcTmp, 1);
			$mach = substr($srcTmp, 0, $endIdx + 1);
			$nextBegin = substr($srcTmp, $endIdx + 1);
			if ($nextBegin =~ m/^\s*\[/) {
				($isFind, $endIdx) = &findBracketsEnd($nextBegin, 1);
				my $subMach = substr($nextBegin, 0, $endIdx + 1);
				$mach = $mach.$subMach;
				$nextBegin = substr($nextBegin, $endIdx + 1);
			}
			$tmp = $tmp." $mach";
		}
		# special user format
		elsif ($srcTmp =~ m/^(\w+\*)/) {
			$mach = $1;
			$tmp = $tmp." $mach";
			$nextBegin = substr($srcTmp, length($mach));
		}
		elsif ($srcTmp =~ m/^(\w+)/) {
			$mach = $1;
			$tmp = $tmp." $mach";
			$nextBegin = substr($srcTmp, length($mach));
		}
		elsif ($srcTmp =~ m/^(.*?),/) {
			$mach = $1;
			$tmp = $tmp." $mach";

			my $commaIdx = index($srcTmp, ",");
			$nextBegin = substr($srcTmp, $commaIdx + 1);

			push @subs, &stringTrim($tmp);
			$tmp = "";
		}
		else {
			$mach = $srcTmp;
			$nextBegin = substr($srcTmp, length($mach));

			push @subs, &stringTrim($tmp);
			$tmp = "";
		}

		$srcTmp = $nextBegin;
		$srcTmp = &stringTrim($srcTmp);
	}
	if ("" ne $mach) {
		push @subs, &stringTrim($tmp);
	}
=pod
	print "begin\n";
	foreach (@subs) {
		print $_."\n";
	}
	print "end\n";
=cut

	return \@subs;
}

sub joinSubComplexDataType
{
	my $srcTypes = shift;
	my $result = "";
	my $lastType = -1;
	my $currType = -1;
	foreach my $item (@$srcTypes) {
		if ($item =~ m/^(\w+)/) {
			$currType = 0;
		}
		elsif ($item =~ m/^(,)/) {
			$currType = 1;
		}
		elsif ($item =~ m/^(\<)/) {
			$currType = 2;
		}
		elsif ($item =~ m/^(\>)/) {
			$currType = 2;
		}
		elsif ($item =~ m/^(\[)/) {
			$currType = 2;
		}
		elsif ($item =~ m/^(\])/) {
			$currType = 2;
		}

		if ($currType ne $lastType) {
			if (-1 eq $lastType) {
				$result = $result.$item;
			}
			elsif (1 eq $lastType) {
				$result = $result." ".$item;
			}
			elsif (2 eq $lastType && 1 eq $currType) {
				$result = $result.$item;
			}
			elsif (2 eq $lastType && 0 eq $currType) {
				$result = $result.$item;
			}
			elsif (2 eq $lastType && 2 ne $currType) {
				$result = $result.$item;
			}
			elsif (0 eq $lastType && 2 eq $currType) {
				$item =~ s/\*$//;
				$result = $result.$item;
			}
			else {
				$result = $result.$item;
			}
		}
		else {
			if (0 eq $currType) {
				$result = $result." ".$item;
			}
			else {
				$result = $result.$item;
			}
		}

		$lastType = $currType;
	}
	$result = &stringTrim($result);
	return $result;
}

# input: $input, $bracketsType, ==0"(", ==1"[", ==2"{", ==3"<"
# return: $isFind, $aimIdx
sub findBracketsEnd
{
	my $input = shift;
	my $bracketsType = shift;
	my $direction = shift; # "->" left to right, "<-" right to left
	my $offset = shift;

	if (!defined($direction)) { $direction = "->"; }
	if (!defined($offset)) {
		if ("->" eq $direction) { $offset = 0; }
		else { $offset = length($input) - 1; }
	}

	my ($isFind, $aimIdx);
	$isFind = 0;
	$aimIdx = -1;
	my ($firstIdx, $isLeftBrackets);
	$firstIdx = -1;
	$isLeftBrackets = -1;
	if (0 eq $bracketsType) {
		($firstIdx, $isLeftBrackets) = &findFirstSmallBrackets($input, $offset, $direction);
	}
	elsif (1 eq $bracketsType) {
		($firstIdx, $isLeftBrackets) = &findFirstMiddleBrackets($input, $offset, $direction);
	}
	elsif (2 eq $bracketsType) {
		($firstIdx, $isLeftBrackets) = &findFirstBigBrackets($input, $offset, $direction);
	}
	elsif (3 eq $bracketsType) {
		($firstIdx, $isLeftBrackets) = &findFirstSharpBrackets($input, $offset, $direction);
	}

	#print __LINE__." findBracketsEnd\n";

	if ($firstIdx >= 0 && "->" eq $direction && 1 eq $isLeftBrackets) {
		my $findEndOk = 0;
		my $bracketsCnt = 1;
		while ($bracketsCnt > 0) {
			++$firstIdx;
			#print __LINE__." findBracketsEnd, \$bracketsCnt=$bracketsCnt\n";
			#sleep 1;

			if (0 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstSmallBrackets($input, $firstIdx, $direction);
			}
			elsif (1 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstMiddleBrackets($input, $firstIdx, $direction);
			}
			elsif (2 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstBigBrackets($input, $firstIdx, $direction);
			}
			elsif (3 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstSharpBrackets($input, $firstIdx, $direction);
			}
			if ($firstIdx >= 0) {
				if (1 eq $isLeftBrackets) { ++$bracketsCnt; }
				elsif (0 eq $isLeftBrackets) { --$bracketsCnt; }
				else {
					print __LINE__." input is not complete, failed\n";
					last;
				}
			}
			else {
				print __LINE__." input is not complete, failed\n";
				<STDIN>;
				last;
			}
			if (0 eq $bracketsCnt) {
				$findEndOk = 1;
				last;
			}
		}
		if (1 == $findEndOk) {
			$isFind = 1;
			$aimIdx = $firstIdx;
		}
	}
	elsif ($firstIdx >= 0 && "<-" eq $direction && 0 eq $isLeftBrackets) {
		my $findEndOk = 0;
		my $bracketsCnt = 1;
		while ($bracketsCnt > 0) {
			--$firstIdx;
			if (0 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstSmallBrackets($input, $firstIdx, $direction);
			}
			elsif (1 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstMiddleBrackets($input, $firstIdx, $direction);
			}
			elsif (2 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstBigBrackets($input, $firstIdx, $direction);
			}
			elsif (3 eq $bracketsType) {
				($firstIdx, $isLeftBrackets) = &findFirstSharpBrackets($input, $firstIdx, $direction);
			}
			if ($firstIdx >= 0) {
				if (0 eq $isLeftBrackets) { ++$bracketsCnt; }
				elsif (1 eq $isLeftBrackets) { --$bracketsCnt; }
				else {
					print __LINE__." input is not complete, failed\n";
					last;
				}
			}
			else {
				print __LINE__." input is not complete, failed\n";
				last;
			}
			if (0 eq $bracketsCnt) {
				$findEndOk = 1;
				last;
			}
		}
		if (1 == $findEndOk) {
			$isFind = 1;
			$aimIdx = $firstIdx;
		}
	}
	return ($isFind, $aimIdx);
}

# input: $input, $startIdx
# return: $firstIdx, $isLeftBrackets
sub findFirstSmallBrackets
{
	my $input = shift;
	my $startIdx = shift;
	my $direction = shift;
	return &findFirstSpecifyBrackets($input, $startIdx, $direction, "(", ")");
}

# input: $input
# return: $firstIdx, $isLeftBrackets
sub findFirstMiddleBrackets
{
	my $input = shift;
	my $startIdx = shift;
	my $direction = shift;
	return &findFirstSpecifyBrackets($input, $startIdx, $direction, "[", "]");
}

# input: $input
# return: $firstIdx, $isLeftBrackets
sub findFirstBigBrackets
{
	my $input = shift;
	my $startIdx = shift;
	my $direction = shift;
	return &findFirstSpecifyBrackets($input, $startIdx, $direction, "{", "}");
}

sub findFirstSharpBrackets
{
	my $input = shift;
	my $startIdx = shift;
	my $direction = shift;
	return &findFirstSpecifyBrackets($input, $startIdx, $direction, "<", ">");
}

# input: $input, $leftBrackets, $rightBrackets
# return: $firstIdx, $isLeftBrackets
sub findFirstSpecifyBrackets
{
	my $input = shift;
	my $startIdx = shift;
	my $direction = shift;
	my $leftBrackets = shift;
	my $rightBrackets = shift;

	#print __LINE__." \$startIdx=$startIdx\n";

	my ($firstIdx, $isLeftBrackets);
	$firstIdx = -1;
	$isLeftBrackets = -1;

	my $leftBracketsIdx;
	my $rightBracketsIdx;
	if ("->" eq $direction) {
		$leftBracketsIdx = index($input, "$leftBrackets", $startIdx);
		$rightBracketsIdx = index($input, "$rightBrackets", $startIdx);
		if ($leftBracketsIdx < 0 && $rightBracketsIdx >= 0) {
			$firstIdx = $rightBracketsIdx;
			$isLeftBrackets = 0;
		}
		elsif ($leftBracketsIdx >= 0 && $rightBracketsIdx < 0) {
			$firstIdx = $leftBracketsIdx;
			$isLeftBrackets = 1;
		}
		elsif ($leftBracketsIdx >= 0 && $rightBracketsIdx >= 0) {
			if ($leftBracketsIdx < $rightBracketsIdx) {
				$firstIdx = $leftBracketsIdx;
				$isLeftBrackets = 1;
			}
			else {
				$firstIdx = $rightBracketsIdx;
				$isLeftBrackets = 0;
			}
		}
		# both equal -1;
		else {
			$firstIdx = -1;
			$isLeftBrackets = -1;
		}
	}
	else {
		$leftBracketsIdx = rindex($input, "$leftBrackets", $startIdx);
		$rightBracketsIdx = rindex($input, "$rightBrackets", $startIdx);
		if ($leftBracketsIdx < 0 && $rightBracketsIdx >= 0) {
			$firstIdx = $rightBracketsIdx;
			$isLeftBrackets = 0;
		}
		elsif ($leftBracketsIdx >= 0 && $rightBracketsIdx < 0) {
			$firstIdx = $leftBracketsIdx;
			$isLeftBrackets = 1;
		}
		elsif ($leftBracketsIdx >= 0 && $rightBracketsIdx >= 0) {
			if ($leftBracketsIdx < $rightBracketsIdx) {
				$firstIdx = $rightBracketsIdx;
				$isLeftBrackets = 0;
			}
			else {
				$firstIdx = $leftBracketsIdx;
				$isLeftBrackets = 1;
			}
		}
		# both equal -1;
		else {
			$firstIdx = -1;
			$isLeftBrackets = -1;
		}
	}

	#print __LINE__." specifyBrackets: \$startIdx=$startIdx, $leftBrackets=$leftBracketsIdx, $rightBrackets=$rightBracketsIdx, \$isLeftBrackets=$isLeftBrackets\n";
	return ($firstIdx, $isLeftBrackets);
}



1;
