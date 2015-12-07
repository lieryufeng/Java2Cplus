#!/usr/bin/perl;

package ToolcheckObviousError;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( checkObviousErrorInFiles, checkObviousErrorInFile );
use strict;
use FileOperate;


sub checkObviousErrorInFiles
{
    my $files = shift;
	foreach my $file (@$files) {
		print __LINE__.": \$file=$file\n";
		&checkObviousErrorInFile($file);
	}
}

sub checkObviousErrorInFile
{
	my $input = shift;
	my $fileLines = FileOperate::readFile($input);
	&checkObviouslyErrorInner($input, $fileLines);
}

sub checkObviouslyErrorInner
{
	my $filePath = shift;
	my $fileLines = shift;
	my $line;
	my $lineIdx = 0;
	for (my $idx=0; $idx<=@$fileLines; ++$idx) {
		$line = @$fileLines[$idx];
		$lineIdx = $idx + 1;
		&checkVarNoClassScopeInCpp($filePath, $line, $fileLines, $lineIdx);
		&checkStringInit($filePath, $line, $fileLines, $lineIdx);
		&checkStaticSign($filePath, $line, $fileLines, $lineIdx);
		&checkVirtualSign($filePath, $line, $fileLines, $lineIdx);
		&checkFileMacro($filePath, $line, $fileLines, $lineIdx);		
		&checkSampleDataType($filePath, $line, $fileLines, $lineIdx);	
		&checkCppCARAPI($filePath, $line, $fileLines, $lineIdx);	
		&checkNative($filePath, $line, $fileLines, $lineIdx);
		&checkAssert($filePath, $line, $fileLines, $lineIdx);
		&checkAutoPtrGet($filePath, $line, $fileLines, $lineIdx);
		&checkHasReturnBeforeNOERROR($filePath, $line, $fileLines, $lineIdx);
		&checkCppFuncHasClassScope($filePath, $line, $fileLines, $lineIdx);
		&checkCppFuncECodeHasReturn($filePath, $line, $fileLines, $lineIdx);
		&checkCppElseIsNewLine($filePath, $line, $fileLines, $lineIdx);
		&checkInteger($filePath, $line, $fileLines, $lineIdx);
		&checkPointerWhenRetECode($filePath, $line, $fileLines, $lineIdx);
		&checkFuncNameFirstIsUpper($filePath, $line, $fileLines, $lineIdx);
		&checkBeforeTotalUpperConstVarItsSymbol($filePath, $line, $fileLines, $lineIdx);
		&checkArrayOfInitUseCommonNew($filePath, $line, $fileLines, $lineIdx);
		&checkIObject($filePath, $line, $fileLines, $lineIdx);
		&checkNewInH($filePath, $line, $fileLines, $lineIdx);
		&checkRetHasCARAPIInH($filePath, $line, $fileLines, $lineIdx);
	}
}

sub checkVarNoClassScopeInCpp
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\S+.*(\S+);\s*$/ && $line !~ m/::/ 
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] has no class scope.\n";
	}
}

sub checkStringInit
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h/ && $line =~ m/;\s*$/ && $line =~ m/String/ && $line =~ m/=/ && $line !~ m/\(/ 
		&& $line !~ m/\)/ && $line =~ m/^\s+/ && $line =~ m/\"/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] String should not has equal in .h\n";
	}
	if ($path =~ m/.cpp/ && $line =~ m/;\s*$/ && $line =~ m/String/ && $line =~ m/=/ && $line !~ m/\(/ 
		&& $line !~ m/\)/ && $line !~ m/^\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] String should not has equal in .cpp\n";
	}
}

sub checkStaticSign
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp/ && $line =~ m/^(static\s+)\S+.*;\s*$/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] static should not exist in .cpp\n";
	}
}

sub checkVirtualSign
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h/ && $line =~ m/virtual/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		$line = @$lines[$lineIdx - 2];
		if ($line =~ m/\@Override/)
		{
			print __LINE__." [E] [ln=$lineIdx] virtual should not be here bacause last line has \@Override sign\n";
		}		
	}
	if ($path =~ m/.cpp/ && $line =~ m/virtual/) {
		print __LINE__." [E] [ln=$lineIdx] virtual should not exist in .cpp\n";
	}
}

sub checkFileMacro
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h/ && $line =~ m/^#ifndef\s+(\S+)/ && $line !~ m/_ELASTOS_/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] macro has no namespace prefix\n";
	}
}

sub checkSampleDataType
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if (($line =~ m/int\s+/ || $line =~ m/long\s+/ || $line =~ m/float\s+/ || $line =~ m/double\s+/
		|| $line =~ m/void\s+/ || $line =~ m/boolean\s+/ || $line =~ m/true|false/) 
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] has basal data type\n";
	}
}

sub checkCppCARAPI
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/CARAPI\s+/ 
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] CARAPI should not appear in cpp file\n";
	}
}

sub checkNative
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/native\s+/ 
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] native key should not be appear\n";
	}
}

sub checkAssert
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/assert\s+/ && $line !~ m/assert\s*\(/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] assert should add () best\n";
	}
}

sub checkAutoPtrGet
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/->Get\(\)/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] is autoptr ->Get() ?\n";
	}
}

sub checkHasReturnBeforeNOERROR
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/NOERROR/ && $line !~ m/return\s+NOERROR/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] NOERROR before has no return\n";
	}
}

sub checkCppFuncHasClassScope
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\S+/ && $line =~ m/\(/ && $line !~ m/::/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] maybe a function has no class scope\n";
	}
}

sub checkCppFuncECodeHasReturn
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^ECode\s+/ && $line =~ m/\(/ && $line =~ m/::/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		my $subLine;
		for (my $idx=$lineIdx; $idx<=@$lines; ++$idx) {
			$subLine = @$lines[$idx];
			if ($subLine =~ m/^}\s*$/) {
				#print __LINE__." \$idx=$idx ";
				my $lastIdx = $idx - 1;
				$subLine = @$lines[$lastIdx];
				#print " \$lastIdx=$lastIdx\n ";
				if ($subLine !~ m/^\s+return\s+/) {
					print __LINE__." [E] [ln=$lineIdx] func has no return, may be return NOERROR;? sub=$subLine\n";
					last;
				}
				last;
			}
		}
	}
}

sub checkCppElseIsNewLine
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/else\s+/ && $line !~ m/^\s+else/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] else if or else should start at a new line\n";
	}
}

sub checkInteger
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/\s*Integer\s*/ && $line !~ m/\w+Integer/ && $line !~ m/Integer\w+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		print __LINE__." [E] [ln=$lineIdx] Integer may be translate to IInteger32?\n";
	}
}

sub checkPointerWhenRetECode
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^ECode\s+/ && $line =~ m/\(/ && $line =~ m/::/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) {
		my @funcDefs;
		push @funcDefs, $line;
		my $lineIdxTmp = $lineIdx;
		my $subLine = @$lines[$lineIdxTmp++];
		while ($subLine !~ m/^{\s*$/) {
			push @funcDefs, $subLine;
			$subLine = @$lines[$lineIdxTmp++];
		}
		
		my $funcDefine = join " ", @funcDefs;	
		my @pointers;
		my $machTmp;
		while ($funcDefine =~ m/(\S+\*\s+\w+)/mg) {
			$machTmp = $1;
			if ($machTmp !~ m/\/\*\s+\w+/ && $machTmp =~ m/\S+\*\s+(\w+)/mg)
			{
				push @pointers, $1;
			}			
		}
		
		$subLine = @$lines[$lineIdxTmp++];
		my $pointerCnt = $#pointers;
		while ($pointerCnt-- >= 0) {
			if ($subLine !~ m/^\s*VALIDATE_NOT_NULL\(\w+\)/) {
				print __LINE__." [E] [ln=$lineIdx] when ret is ECode, func parm pointer should be checked by VALIDATE_NOT_NULL(p)\n";
			}
			$subLine = @$lines[$lineIdxTmp++];
		}		
	}
}

# check func name first letter is upper
sub checkFuncNameFirstIsUpper
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) { 
		my $machTmp;
		my $maybeFuncName;
		while ($line =~ m/^(.*\w+\s*\()/mg) {
			$machTmp = $1;
			if ($machTmp !~ m/,\s+(\w+)\(/
				&& ($machTmp =~ m/^\s+(\w+)\(/ || $machTmp =~ m/\.(\w+)\(/ 
					|| $machTmp =~ m/->(\w+)\(/ || $machTmp =~ m/=\s*(\w+)\(/)) {	
				if ($machTmp =~ m/(\w+)\(/) {
					$machTmp = $1;
					if ($machTmp !~ m/^if$/ && $machTmp !~ m/^else$/ && $machTmp !~ m/^else if$/
						&& $machTmp !~ m/^for$/ && $machTmp !~ m/^switch$/ && $machTmp !~ m/^while$/) {
						$maybeFuncName = ucfirst($machTmp);
						if ($maybeFuncName ne $machTmp && $machTmp ne "sizeof" && $machTmp ne "assert") {
							print __LINE__." [E] [ln=$lineIdx] is funcName first letter is lowwer?\n";
						}
					}
				}				
			}		
		
		}			
	}
}

# check const var that all letter are upper, before it is "." or "::" ?
sub checkBeforeTotalUpperConstVarItsSymbol
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) { 
		my $machTmp;
		my $machBaseTypeTmp;
		my $machCstVarTmp;
		my $machCstVarUpperTmp;
		while ($line =~ m/(\S+\.\S+)/mg) {
			$machTmp = $1;
			if ($machTmp !~ m/\"(\w+)\.(\w+)/ && $machTmp !~ m/(\w+)\.(\w+)\(/ && $machTmp =~ m/(\w+)\.(\w+)/) {
				$machBaseTypeTmp = $1;
				$machCstVarTmp = $2;
				$machCstVarUpperTmp = $machCstVarTmp;
				$machCstVarUpperTmp =~ tr/[a-z]/[A-Z]/;
				if ($machCstVarUpperTmp eq $machCstVarTmp) {
					print __LINE__." [E] [ln=$lineIdx] is this should be Interface::VAR ? \n";
				}
			}
		}		
	}
}

# ArrayOf used new?
sub checkArrayOfInitUseCommonNew
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/ArrayOf</ && $line =~ m/=/ && $line =~ m/=\s*new\s+ArrayOf</
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) { 
		print __LINE__." [E] [ln=$lineIdx] ArrayOf should use Alloc when initialized\n";		
	}
}

sub checkIObject
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/IObject/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) { 
		print __LINE__." [E] [ln=$lineIdx] should use Object replace\n";		
	}
}

sub checkNewInH
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h$/ && $line =~ m/new\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) { 
		print __LINE__." [E] [ln=$lineIdx] new operator should not appear in .h file\n";		
	}
}

# check return type is whether has CARAPI or CARAPI_( sign in .h file
sub checkRetHasCARAPIInH
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h$/ && $line =~ m/\(/ && $line =~ m/\S+\s+\S+\(/ 
		&& $line !~ m/CARAPI/ && $line !~ m/::/ && $line !~ m/=/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/) { 
		print __LINE__." [E] [ln=$lineIdx] func return has no CARAPI or CARAPI_() sign .h file\n";		
	}
}

1;
