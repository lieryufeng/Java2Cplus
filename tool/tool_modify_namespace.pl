#!/usr/bin/perl


# used for modify namespace for spacify path
my $gBaseDir;
my @gAllJavaFilesPath;
my $gMacroNamespacePrefix = "ELASTOS_DROID_WEBKIT_CONTENT_BROWSER";
my $ret = &Main;

sub Main
{
	&GetWorkDir;
	&GetAllJavaFilesPath($gBaseDir);
	&AddNamespaceForFiles;
}

sub GetWorkDir
{
	$gMacroNamespacePrefix = "ELASTOS_DROID_WEBKIT_CONTENT_BROWSER";
	$gBaseDir = "/home/lieryufeng/self/program/work_dir/ElastosRDK5_0/Sources/Elastos/Frameworks/Droid/Base/Core/inc/webkit/native/content/browser";
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
		if ($filePath =~ m/^*.h$/)
	    {
		    push(@gAllJavaFilesPath, $filePath);
	    }			
		elsif (-d $filePath)
		{
			&GetAllJavaFilesPath($filePath);
		}
	}
}

sub AddNamespaceForFiles
{
	foreach my $file (@gAllJavaFilesPath)
	{
		print __LINE__.": \$file=$file\n";
		&AddNamespaceForFile($file);
	}
}

sub AddNamespaceForFile
{
	my $input = shift;
	my @fileLines = &ReadFile($input);
	@fileLines = &AddNamespace($input, \@fileLines);
	&WriteFile($input, \@fileLines);
}

sub AddNamespace
{
	my $filePath = shift;
	my $fileLines = shift;
	my @ret;
	my $fileNameUpper = &BuildDotHMicroFromDotHFilePath($filePath);
	foreach my $line (@$fileLines)
	{
		if ($line =~ m/^#ifndef\s+(\S+)/)
		{
			$line = "#ifndef _$gMacroNamespacePrefix"."_".$fileNameUpper."_\n";			
		}
		elsif ($line =~ m/^#define\s+(\S+)/)
		{
			$line = "#define _$gMacroNamespacePrefix"."_".$fileNameUpper."_\n";
		}
		elsif ($line =~ m/^#endif\s+\/\/\s+(\S+)/)
		{
			$line = "#endif \/\/\ _$gMacroNamespacePrefix"."_".$fileNameUpper."_\n";
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
    $input =~ s/\./_/;    
    $input =~ tr/[a-z]/[A-Z]/;
    return $input;
}
