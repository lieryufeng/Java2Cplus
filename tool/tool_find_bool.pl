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
	&FindBoolInFiles;
}

sub GetWorkDir
{
	$gBaseDir = "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/ui";
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

sub FindBoolInFiles
{
	foreach my $file (@gAllJavaFilesPath)
	{
		print __LINE__.": \$file=$file\n";
		&FindBoolInFile($file);
	}
}

sub FindBoolInFile
{
	my $input = shift;
	my @fileLines = &ReadFile($input);
	&FindBool($input, \@fileLines);
}

sub FindBool
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
			if ($line !~ m/\/\// && $line !~ m/\*/
				&& ($line =~ m/true/ || $line =~ m/false/))
			{
				$lineIdx = $idx + 1;
				print __LINE__." [E] [line:$lineIdx] find common bool.\n";
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