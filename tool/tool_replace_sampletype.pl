#!/usr/bin/perl


# used for modify namespace for spacify path
my $gBaseDir;
my @gAllJavaFilesPath;
my $ret = &Main;

sub Main
{
	&GetWorkDir;
	&GetAllJavaFilesPath($gBaseDir);
	&ReplaceSampleTypeForFiles;
}

sub GetWorkDir
{
#	$gBaseDir = "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/net";
	$gBaseDir = "/home/lieryufeng/self/program/Self_Project/JavaToCplus_nfmt";
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

sub ReplaceSampleTypeForFiles
{
	foreach my $file (@gAllJavaFilesPath)
	{
		print __LINE__.": \$file=$file\n";
		&ReplaceSampleTypeForFile($file);
	}
}

sub ReplaceSampleTypeForFile
{
	my $input = shift;
	my @fileLines = &ReadFile($input);
	@fileLines = &ReplaceSampleType($input, \@fileLines);
	&WriteFile($input, \@fileLines);
}

sub ReplaceSampleType
{
	my $filePath = shift;
	my $fileLines = shift;
	my @ret;
	my $line;
	my $lastLine;
	my $match;
	for (my $idx=0; $idx<=@$fileLines; ++$idx)
	{
		$line = @$fileLines[$idx];
		if ($line =~ m/^\s+(virtual\s+)\S+/)
		{
			$match = $1;
			$lastLine = @$fileLines[$idx - 1];	
			if ($lastLine =~ m/^\s+\/\/\s*\@Override/)
			{
				$line =~ s/$match//;
			}
		}

		push (@ret, $line);
	}
	return @ret;
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