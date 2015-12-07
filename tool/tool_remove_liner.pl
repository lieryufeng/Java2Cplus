#!/usr/bin/perl

my $gBaseDir;
my @gAllJavaFilesPath;
my $gIsTesting = 0;
my $ret = &Main;

sub Main
{
	my @workDirs = &GetWorkDir;
	foreach my $dir (@workDirs)
	{
		&GetAllFiles($dir);
	}
	&RemoveFilesLineR;
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
		if ($filePath =~ m/^*.h/ || $filePath =~ m/^*.cpp/)
	    {
		    push(@gAllJavaFilesPath, $filePath);
	    }			
		elsif (-d $filePath)
		{
			&GetAllFiles($filePath);
		}
	}
}

sub RemoveFilesLineR
{
	foreach my $file (@gAllJavaFilesPath)
	{
		&RemoveFileLineR($file);
	}
}

sub RemoveFileLineR
{
	my $input = shift;
	my @fileLines = &ReadFile($input);
	@fileLines = &RemoveLineR(@fileLines);
	&WriteFile($input, \@fileLines);
}

sub RemoveLineR
{
	my @input = @_;
	my @ret;
	foreach my $line (@input)
	{
		$line =~ s/\r//g;
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

