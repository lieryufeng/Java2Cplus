#!/usr/bin/perl


# used for modify namespace for spacify path
my $gBaseDir;
my @gAllJavaFilesPath;
my $gMacroNamespacePrefix = "ELASTOS_DROID_WEBKIT_UI";
my $ret = &Main;

sub Main
{
	&GetWorkDir;
	&GetAllJavaFilesPath($gBaseDir);
	&FindStringEqualInFiles;
}

sub GetWorkDir
{
	$gBaseDir = "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/src/webkit/native/ui";
#	$gBaseDir = "/home/lieryufeng/self/program/Self_Project/JavaToCplus_nfmt";
}

sub GetAllJavaFilesPath
{
	my $currDir = $_[0];
	opendir(DIR, $currDir || die "can't open this $currDir");
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
		    push(@gAllJavaFilesPath, $filePath);
	    }			
		elsif (-d $filePath)
		{
			&GetAllJavaFilesPath($filePath);
		}
	}
}

sub FindStringEqualInFiles
{
	foreach my $file (@gAllJavaFilesPath)
	{
		print __LINE__.": \$file=$file\n";
		&FindStringEqualInFile($file);
	}
}

sub FindStringEqualInFile
{
	my $input = shift;
	my @fileLines = &ReadFile($input);
	&FindStringEqual($input, \@fileLines);
}

sub FindStringEqual
{
	my $filePath = shift;
	my $fileLines = shift;
	my $line;
	my $lineIdx = 0;
	if ($filePath =~ m/\.h$/)
	{
		for (my $idx=0; $idx<=@$fileLines; ++$idx)
		{
			$line = @$fileLines[$idx];
			if ($line =~ m/;\s*$/ && $line =~ m/String/ 
				&& $line =~ m/=/ && $line !~ m/\(/ 
				&& $line !~ m/\)/ && $line =~ m/^\s+/)
			{
				$lineIdx = $idx + 1;
				print __LINE__." [E] [line:$lineIdx] String has equal.\n";
			}
		}
	}
	elsif ($filePath =~ m/\.cpp$/)
	{
		for (my $idx=0; $idx<=@$fileLines; ++$idx)
		{
			$line = @$fileLines[$idx];
			if ($line =~ m/;\s*$/ && $line =~ m/String/ 
				&& $line =~ m/=/ && $line !~ m/\(/ 
				&& $line !~ m/\)/ && $line !~ m/^\s+/)
			{
				$lineIdx = $idx + 1;
				print __LINE__." [E] [line:$lineIdx] String has equal.\n";
			}
		}
	}
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

# input: file path
# return: .h file micro 
sub BuildDotHMicroFromDotHFilePath
{
    my $input = $_[0];
    my @names = split(/\//, $input);
    my $fileName = $names[$#names];
    my $ret = &BuildDotHMicroFromDotHFileName($fileName);
    return $ret;
}

# input: file path
# return: .h file micro 
sub BuildDotHMicroFromDotHFileName
{
    my $input = $_[0];
    #print "filename=$input\n";
    $input =~ s/\./_/;    
    $input =~ tr/[a-z]/[A-Z]/;
    return $input;
}