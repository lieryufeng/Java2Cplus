#!/usr/bin/perl
use strict;

# used for modify namespace for spacify path
my @gAllFilesPath;
my @gDotHRegs;
my @gDotCppRegs;
my $gIsTesting = 0;
my $ret = &Main;

sub Main
{
	my @workDirs = &GetWorkDir;
	foreach my $dir (@workDirs)
	{
		&GetAllFiles($dir);
	}	
	&CheckObviouslyErrorInFiles;
}

sub GetWorkDir
{
	my @dirs;
	if (0 eq $gIsTesting)
	{
		push @dirs, "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/net";
		push @dirs, "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/ui";
		push @dirs, "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/net";
		push @dirs, "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui";
	}
	else
	{
		push @dirs, "/home/lieryufeng/self/program/Self_Project/JavaToCplus_nfmt";
	}
	return @dirs;
}

sub GetAllFiles
{	
	my $currDir = shift;
	opendir(DIR, $currDir) || die "can't open this $currDir";
	my @files = readdir(DIR);
	closedir(DIR);
    my $filePath;
	foreach my $file (@files)
	{
	    $filePath = $currDir."/".$file;
		next if ($file =~ m/^\.$/ || $file =~ m/^\.\.$/);
		next if ($file =~ m/^*.p.*l$/ || $file =~ m/^*.p.*l~$/);
		if ($filePath =~ m/^*.h$/ || $filePath =~ m/^*.cpp$/)
	    {
		    push(@gAllFilesPath, $filePath);
	    }			
		elsif (-d $filePath)
		{
			&GetAllFiles($filePath);
		}
	}
}

sub CheckObviouslyErrorInFiles
{
	foreach my $file (@gAllFilesPath)
	{
		print __LINE__.": \$file=$file\n";
		&CheckObviouslyErrorInFile($file);
	}
}

sub CheckObviouslyErrorInFile
{
	my $input = shift;
	my @fileLines = &ReadFile($input);
	&CheckObviouslyErrorInner($input, \@fileLines);
}

# input: $filePath, @fileData
# return: .cpp file name 
sub ReadFile
{
    my $input = $_[0];
	open (FILE, "<", $input);
	my @fileData = <FILE>;
	close FILE;
	return @fileData;
}

# input: $filePath, @fileData
# return: .cpp file name 
sub WriteFile
{
    my $input = $_[0];
    my $fileData = $_[1];
	open (FILE, ">", $input);
	print FILE (@$fileData);
	close FILE;
}

sub CheckObviouslyErrorInner
{
	my $filePath = shift;
	my $fileLines = shift;
	my $line;
	my $lineIdx = 0;
	for (my $idx=0; $idx<=@$fileLines; ++$idx)
	{
		$line = @$fileLines[$idx];
		$lineIdx = $idx + 1;
		&CheckVarNoClassScopeInCpp($filePath, $line, $fileLines, $lineIdx);
		&CheckStringInit($filePath, $line, $fileLines, $lineIdx);
		&CheckStaticSign($filePath, $line, $fileLines, $lineIdx);
		&CheckVirtualSign($filePath, $line, $fileLines, $lineIdx);
		&CheckFileMacro($filePath, $line, $fileLines, $lineIdx);		
		&CheckSampleDataType($filePath, $line, $fileLines, $lineIdx);	
		&CheckCppCARAPI($filePath, $line, $fileLines, $lineIdx);	
		&CheckNative($filePath, $line, $fileLines, $lineIdx);
		&CheckAssert($filePath, $line, $fileLines, $lineIdx);
		&CheckAutoPtrGet($filePath, $line, $fileLines, $lineIdx);
		&CheckHasReturnBeforeNOERROR($filePath, $line, $fileLines, $lineIdx);
		&CheckCppFuncHasClassScope($filePath, $line, $fileLines, $lineIdx);
		&CheckCppFuncECodeHasReturn($filePath, $line, $fileLines, $lineIdx);
		&CheckCppElseIsNewLine($filePath, $line, $fileLines, $lineIdx);
		&CheckInteger($filePath, $line, $fileLines, $lineIdx);
		&CheckPointerWhenRetECode($filePath, $line, $fileLines, $lineIdx);
		&CheckFuncNameFirstIsUpper($filePath, $line, $fileLines, $lineIdx);
		&CheckBeforeTotalUpperConstVarItsSymbol($filePath, $line, $fileLines, $lineIdx);
		&CheckArrayOfInitUseCommonNew($filePath, $line, $fileLines, $lineIdx);
		&CheckIObject($filePath, $line, $fileLines, $lineIdx);
		&CheckNewInH($filePath, $line, $fileLines, $lineIdx);
		&CheckRetHasCARAPIInH($filePath, $line, $fileLines, $lineIdx);
	}
}

sub CheckVarNoClassScopeInCpp
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\S+.*(\S+);\s*$/ && $line !~ m/::/ 
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] has no class scope.\n";
	}
}

sub CheckStringInit
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h/ && $line =~ m/;\s*$/ && $line =~ m/String/ && $line =~ m/=/ && $line !~ m/\(/ 
		&& $line !~ m/\)/ && $line =~ m/^\s+/ && $line =~ m/\"/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] String should not has equal in .h\n";
	}
	if ($path =~ m/.cpp/ && $line =~ m/;\s*$/ && $line =~ m/String/ && $line =~ m/=/ && $line !~ m/\(/ 
		&& $line !~ m/\)/ && $line !~ m/^\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] String should not has equal in .cpp\n";
	}
}

sub CheckStaticSign
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp/ && $line =~ m/^(static\s+)\S+.*;\s*$/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] static should not exist in .cpp\n";
	}
}

sub CheckVirtualSign
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h/ && $line =~ m/virtual/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		$line = @$lines[$lineIdx - 2];
		if ($line =~ m/\@Override/)
		{
			print __LINE__." [E] [ln=$lineIdx] virtual should not be here bacause last line has \@Override sign\n";
		}		
	}
	if ($path =~ m/.cpp/ && $line =~ m/virtual/)
	{
		print __LINE__." [E] [ln=$lineIdx] virtual should not exist in .cpp\n";
	}
}

sub CheckFileMacro
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h/ && $line =~ m/^#ifndef\s+(\S+)/ && $line !~ m/_ELASTOS_/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] macro has no namespace prefix\n";
	}
}

sub CheckSampleDataType
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

sub CheckCppCARAPI
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

sub CheckNative
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/native\s+/ 
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] native key should not be appear\n";
	}
}

sub CheckAssert
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/assert\s+/ && $line !~ m/assert\s*\(/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] assert should add () best\n";
	}
}

sub CheckAutoPtrGet
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/->Get\(\)/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] is autoptr ->Get() ?\n";
	}
}

sub CheckHasReturnBeforeNOERROR
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

sub CheckCppFuncHasClassScope
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\S+/ && $line =~ m/\(/ && $line !~ m/::/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] maybe a function has no class scope\n";
	}
}

sub CheckCppFuncECodeHasReturn
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^ECode\s+/ && $line =~ m/\(/ && $line =~ m/::/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		my $subLine;
		for (my $idx=$lineIdx; $idx<=@$lines; ++$idx)
		{
			$subLine = @$lines[$idx];
			if ($subLine =~ m/^}\s*$/)
			{
				#print __LINE__." \$idx=$idx ";
				my $lastIdx = $idx - 1;
				$subLine = @$lines[$lastIdx];
				#print " \$lastIdx=$lastIdx\n ";
				if ($subLine !~ m/^\s+return\s+/)
				{
					print __LINE__." [E] [ln=$lineIdx] func has no return, may be return NOERROR;? sub=$subLine\n";
					last;
				}
				last;
			}
		}
	}
}

sub CheckCppElseIsNewLine
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/else\s+/ && $line !~ m/^\s+else/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] else if or else should start at a new line\n";
	}
}

sub CheckInteger
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/\s*Integer\s*/ && $line !~ m/\w+Integer/ && $line !~ m/Integer\w+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		print __LINE__." [E] [ln=$lineIdx] Integer may be translate to IInteger32?\n";
	}
}

sub CheckPointerWhenRetECode
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^ECode\s+/ && $line =~ m/\(/ && $line =~ m/::/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{
		my @funcDefs;
		push @funcDefs, $line;
		my $lineIdxTmp = $lineIdx;
		my $subLine = @$lines[$lineIdxTmp++];
		while ($subLine !~ m/^{\s*$/)
		{
			push @funcDefs, $subLine;
			$subLine = @$lines[$lineIdxTmp++];
		}
		
		my $funcDefine = join " ", @funcDefs;	
		my @pointers;
		my $machTmp;
		while ($funcDefine =~ m/(\S+\*\s+\w+)/mg)
		{
			$machTmp = $1;
			if ($machTmp !~ m/\/\*\s+\w+/ && $machTmp =~ m/\S+\*\s+(\w+)/mg)
			{
				push @pointers, $1;
			}			
		}
		
		$subLine = @$lines[$lineIdxTmp++];
		my $pointerCnt = $#pointers;
		while ($pointerCnt-- >= 0)
		{
			if ($subLine !~ m/^\s*VALIDATE_NOT_NULL\(\w+\)/)
			{
				print __LINE__." [E] [ln=$lineIdx] when ret is ECode, func parm pointer should be checked by VALIDATE_NOT_NULL(p)\n";
			}
			$subLine = @$lines[$lineIdxTmp++];
		}		
	}
}

# check func name first letter is upper
sub CheckFuncNameFirstIsUpper
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{ 
		my $machTmp;
		my $maybeFuncName;
		while ($line =~ m/^(.*\w+\s*\()/mg)
		{
			$machTmp = $1;
			if ($machTmp !~ m/,\s+(\w+)\(/
				&& ($machTmp =~ m/^\s+(\w+)\(/ || $machTmp =~ m/\.(\w+)\(/ 
					|| $machTmp =~ m/->(\w+)\(/ || $machTmp =~ m/=\s*(\w+)\(/))
			{	
				if ($machTmp =~ m/(\w+)\(/)
				{
					$machTmp = $1;
					if ($machTmp !~ m/^if$/ && $machTmp !~ m/^else$/ && $machTmp !~ m/^else if$/
						&& $machTmp !~ m/^for$/ && $machTmp !~ m/^switch$/ && $machTmp !~ m/^while$/)
					{
						$maybeFuncName = ucfirst($machTmp);
						if ($maybeFuncName ne $machTmp && $machTmp ne "sizeof" && $machTmp ne "assert")
						{
							print __LINE__." [E] [ln=$lineIdx] is funcName first letter is lowwer?\n";
						}
					}
				}				
			}		
		
		}			
	}
}

# check const var that all letter are upper, before it is "." or "::" ?
sub CheckBeforeTotalUpperConstVarItsSymbol
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.cpp$/ && $line =~ m/^\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{ 
		my $machTmp;
		my $machBaseTypeTmp;
		my $machCstVarTmp;
		my $machCstVarUpperTmp;
		while ($line =~ m/(\S+\.\S+)/mg)
		{
			$machTmp = $1;
			if ($machTmp !~ m/\"(\w+)\.(\w+)/ && $machTmp !~ m/(\w+)\.(\w+)\(/ && $machTmp =~ m/(\w+)\.(\w+)/)
			{
				$machBaseTypeTmp = $1;
				$machCstVarTmp = $2;
				$machCstVarUpperTmp = $machCstVarTmp;
				$machCstVarUpperTmp =~ tr/[a-z]/[A-Z]/;
				if ($machCstVarUpperTmp eq $machCstVarTmp)
				{
					print __LINE__." [E] [ln=$lineIdx] is this should be Interface::VAR ? \n";
				}
			}
		}		
	}
}

# ArrayOf used new?
sub CheckArrayOfInitUseCommonNew
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/ArrayOf</ && $line =~ m/=/ && $line =~ m/=\s*new\s+ArrayOf</
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{ 
		print __LINE__." [E] [ln=$lineIdx] ArrayOf should use Alloc when initialized\n";		
	}
}

sub CheckIObject
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($line =~ m/IObject/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{ 
		print __LINE__." [E] [ln=$lineIdx] should use Object replace\n";		
	}
}

sub CheckNewInH
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h$/ && $line =~ m/new\s+/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{ 
		print __LINE__." [E] [ln=$lineIdx] new operator should not appear in .h file\n";		
	}
}

# check return type is whether has CARAPI or CARAPI_( sign in .h file
sub CheckRetHasCARAPIInH
{
	my $path = shift;
	my $line = shift;
	my $lines = shift;
	my $lineIdx = shift;
	if ($path =~ m/.h$/ && $line =~ m/\(/ && $line =~ m/\S+\s+\S+\(/ 
		&& $line !~ m/CARAPI/ && $line !~ m/::/ && $line !~ m/=/
		&& $line !~ m/^\s*\/\// && $line !~ m/^\s*\*/)
	{ 
		print __LINE__." [E] [ln=$lineIdx] func return has no CARAPI or CARAPI_() sign .h file\n";		
	}
}