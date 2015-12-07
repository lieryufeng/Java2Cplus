#!/usr/bin/perl;

package FileOperate;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( readFile, writeFile, readDirs, readDir, readDirsAndExcepts, readDirAndExcepts );
use strict;

sub readFile {
    my $filePath = shift;
	open (FILE, "<", $filePath) || die "can not open file $filePath.\n";
	my @fileData = <FILE>;
	close FILE;
	return \@fileData;
}

sub writeFile {
    my $filePath = shift;
    my $fileData = shift;
	open (FILE, ">", $filePath) || die "cannot open file $filePath\n";
	print FILE (@$fileData);
	close FILE;
}

sub readDirs {
    my $dirsPath = shift;
    my $endPrefix = shift;
    my @empty;
	my $retRmRepeat = &readDirsAndExcepts($dirsPath, \@empty, $endPrefix);
	return $retRmRepeat;
}

sub readDir {
    my $dirPath = shift;
    my $endPrefix = shift;
	my @empty;
	my $retRmRepeat = &readDirAndExcepts($dirPath, \@empty, $endPrefix);
	return $retRmRepeat;
}

sub unlinkFilesInDir {
    my $dirPath = shift;
    my $endPrefix = shift;
	my @empty;
	my $retRmRepeat = &readDirAndExcepts($dirPath, \@empty, $endPrefix);
	print __LINE__." unlink: foreach\n";
	foreach (@$retRmRepeat) {
		unlink $_;
		print __LINE__." unlink: $_\n";
	}
}

sub readDirsAndExcepts {
    my $dirsPath = shift;
    my $excepts = shift;
    my $endPrefix = shift;
    my @retFiles;
	foreach my $dirPath (@$dirsPath) {
	    my $tmps = &readDirAndExcepts($dirPath, $excepts, $endPrefix);
	    push @retFiles, @$tmps;
	}
	my $retRmRepeat = &removeRepeats(\@retFiles);
	return $retRmRepeat;
}

sub readDirAndExcepts {
    my $dirPath = shift;
    my $excepts = shift;
    my $endPrefix = shift;
    my @retFiles;
	opendir(DIR, $dirPath || die "can't open dir $dirPath");
	my @files = readdir(DIR);
	closedir(DIR);
    my $filePath;
	foreach my $file (@files) {
	    $filePath = $dirPath."/".$file;
	    next if ($file =~ m/^\.$/ || $file =~ m/^\.\.$/);
	    next if ($file =~ m/^*.p.*l$/ || $file =~ m/^*.p.*l~$/);
	    if (0 eq &isSubFiles($filePath, $excepts)) {
		    if ($filePath =~ m/\Q$endPrefix\E$/) {
		        push(@retFiles, $filePath);
	        }
		    elsif (-d $filePath) {
			    my $tmpRetFiles = &readDirAndExcepts($filePath, $excepts, $endPrefix);
			    push(@retFiles, @$tmpRetFiles);
		    }
		}
	}
	my $retRmRepeat = &removeRepeats(\@retFiles);
	return $retRmRepeat;
}

sub readDirForMakefile {
    my $dirPath = shift;
    my %dirsInfo = ();
	&doReadDirForMakefile($dirPath, \%dirsInfo);
	return \%dirsInfo;
}

sub readDirSubFoldersNoRecursive
{
	my $dirPath = shift;
	opendir(DIR, $dirPath || die "can't open dir $dirPath");
	my @files = readdir(DIR);
	closedir(DIR);

	my @filesPath = ();
    my $filePath;
	foreach my $file (@files) {
	    $filePath = $dirPath."/".$file;
	    next if ($file =~ m/^\.$/ || $file =~ m/^\.\.$/);
	    next if ($file =~ m/^*.p.*l$/ || $file =~ m/^*.p.*l~$/);
	    if (-d $filePath) {
		    push @filesPath, $filePath;
	    }
	}
	return \@filesPath;
}

sub readDirSubFoldersHasRecursive
{
	my $dirPath = shift;
	opendir(DIR, $dirPath || die "can't open dir $dirPath");
	my @files = readdir(DIR);
	closedir(DIR);

	my @filesPath = ();
	push @filesPath, $dirPath;
    my $filePath;
	foreach my $file (@files) {
	    $filePath = $dirPath."/".$file;
	    next if ($file =~ m/^\.$/ || $file =~ m/^\.\.$/);
	    next if ($file =~ m/^*.p.*l$/ || $file =~ m/^*.p.*l~$/);
	    if (-d $filePath) {
		    my $subDirs = &readDirSubFoldersHasRecursive($filePath);
		    push @filesPath, @$subDirs;
	    }
	}
	return \@filesPath;
}

sub readDirSubFilesNoRecursive
{
	my $dirPath = shift;
	my $endPrefix = shift;
	my $onlyName = shift;
	opendir(DIR, $dirPath || die "can't open dir [$dirPath]");
	my @files = readdir(DIR);
	closedir(DIR);

	my @filesPath = ();
    my $filePath;
	foreach my $file (@files) {
	    $filePath = $dirPath."/".$file;
	    next if ($file =~ m/^\.$/ || $file =~ m/^\.\.$/);
	    next if ($file =~ m/^*.p.*l$/ || $file =~ m/^*.p.*l~$/);
	    if ($filePath =~ m/\Q$endPrefix\E$/) {
			if (1 eq $onlyName) {
				$file = Util::stringEndTrimStr($file, $endPrefix);
	        	push(@filesPath, $file);
	        }
	        else {
				push(@filesPath, $filePath);
	        }
        }
	}
	return \@filesPath;
}

sub getFileNamesByFileSameLayer
{
	my $path = shift;
	my $endPrefix = shift;
	$path =~ s/\w+$//;
	$path =~ s/\.$//;
	$path =~ s/\w+$//;
	my $sameLayerJavaFiles = &readDirSubFilesNoRecursive($path, $endPrefix, 1);
	return $sameLayerJavaFiles;
}

sub getFilePathsByFileSameLayer
{
	my $path = shift;
	my $endPrefix = shift;
	$path =~ s/\w+$//;
	$path =~ s/\.$//;
	$path =~ s/\w+$//;
	$path =~ s/\/$//;
	my $sameLayerJavaFiles = &readDirSubFilesNoRecursive($path, $endPrefix, 0);
	return $sameLayerJavaFiles;
}

sub doReadDirForMakefile {
    my $dirPath = shift;
    my $dirsInfo = shift;

	opendir(DIR, $dirPath || die "can't open dir $dirPath");
	my @files = readdir(DIR);
	closedir(DIR);

	my @filePaths = ();
    my $filePath;
	foreach my $file (@files) {
	    $filePath = $dirPath."/".$file;
	    next if ($file =~ m/^\.$/ || $file =~ m/^\.\.$/);
	    next if ($file =~ m/^*.p.*l$/ || $file =~ m/^*.p.*l~$/);
	    if ($file =~ m/\.cpp$/) {
	    	if (0 == @filePaths) {
				$dirsInfo->{ $dirPath } = \@filePaths;
	    	}
			push @filePaths, $filePath;
	    }
	    elsif (-d $filePath) {
		    &doReadDirForMakefile($filePath, $dirsInfo);
	    }
	}
}

sub moveDir2Dir
{
	my $srcDir = shift;
    my $dstDir = shift;
	my $endPrefix = shift;

	$dstDir =~ s/\/$//;
	my $srcFiles = &readDir($srcDir, $endPrefix);
	my $aimPath;
	foreach my $path (@$srcFiles) {
		$aimPath = $path;
		$aimPath = Util::stringBeginTrimStr($path, $srcDir);
		$aimPath =~ s/^\///;
		$aimPath = $dstDir."/".$aimPath;
		system("cp $path $aimPath");
		print __LINE__." cp \$path=$path\n";
		print __LINE__." \$aimPath=$aimPath\n";
	}
}

sub isSubFiles {
    my $path = shift;
    my $excepts = shift;
    my $isSub = 0;
    foreach my $tmp (@$excepts) {
        if ($tmp eq $path || $path =~ m/^\Q$isSub\E/) {
            $isSub = 1;
            last;
        }
    }
    return $isSub;
}

sub isFileExists
{
	my $path = shift;
	my $result = 0;
	if (open (FILE, "<", $path)) {
		$result = 1;
	}
	close FILE;
	#print __LINE__." isFileExists: \$path=$path, \$result=$result\n";
	return $result;
}

sub findFile
{
	my $dirPath = shift;
	my $fileName = shift;

	opendir(DIR, $dirPath || die "can't open dir $dirPath");
	my @files = readdir(DIR);
	closedir(DIR);
    my $filePath;
	foreach my $file (@files) {
	    $filePath = $dirPath."/".$file;
	    next if ($file =~ m/^\.$/ || $file =~ m/^\.\.$/);
	    next if ($file =~ m/^*.p.*l$/ || $file =~ m/^*.p.*l~$/);
	    if ($file eq $fileName) {
	        return (1, $filePath);
        }
	    elsif (-d $filePath) {
		    my ($find, $path) = &findFile($filePath, $fileName);
		    if (1 eq $find) {
				return ($find, $path);
		    }
	    }
	}

	return (0, "");
}

sub removeRepeats {
    my $a = shift;
	my %h;
    my @ret = grep { ++$h{$_} < 2 } @$a;
    return \@ret;
}

sub getFileNameByPath
{
	my $path = shift;
	my $endIdx = rindex($path, "/");
	my $result = substr($path, $endIdx+1);
	return $result;
}

1;
