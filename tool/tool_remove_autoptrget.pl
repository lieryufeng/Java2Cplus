#!/usr/bin/perl
use strict;

# used for modify namespace for spacify path
my $gBaseDir;
my @gAllJavaFilesPath;
my $gIsTesting = 1;
my $ret = &Main;

sub Main
{
	my @workDirs = &GetWorkDir;
	foreach my $dir (@workDirs)
	{
		&GetAllJavaFilesPath($dir);
	}
	&RemoveAutoPtrGetsInFiles;
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
		if ($filePath =~ m/^*.cpp$/)
	    {
		    push(@gAllJavaFilesPath, $filePath);
	    }			
		elsif (-d $filePath)
		{
			&GetAllJavaFilesPath($filePath);
		}
	}
}

sub RemoveAutoPtrGetsInFiles
{
	foreach my $file (@gAllJavaFilesPath)
	{
		print __LINE__.": \$file=$file\n";
		&RemoveAutoPtrGetsInFile($file);
	}
}

sub RemoveAutoPtrGetsInFile
{
	my $input = shift;
	my @fileLines = &ReadFile($input);
	&RemoveAutoPtrGets($input, \@fileLines);
}

sub RemoveAutoPtrGets
{
	my $filePath = shift;
	my $fileLines = shift;
	my $line;
	my $lineIdx = 0;
	for (my $idx=0; $idx<=@$fileLines; ++$idx)
	{
		$line = @$fileLines[$idx];
		if ($line =~ m/->Get\(\)/)
		{
			$line =~ s/->Get\(\)//;
			
			$lineIdx = $idx + 1;
			print __LINE__." [E] [line:$lineIdx] find common bool.\n";
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