#!/usr/bin/perl;

package AndroidFilePathTry;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use FileOperate;
use FileTag;
use FileAnalysisStruct;
use ElastosConfig;
use Util;

my $gAllJavaFilePaths;

sub obtAllJavaFilePaths
{
	$gAllJavaFilePaths = FileOperate::readDir($ElastosConfig::CFG_ANDROID_BASE, ".java");
}

sub obtImportStr2JavaPath
{
	my $import = shift;
	$import =~ s/^import\s+//;
	$import =~ s/\s*;\s*$//;
	my ($find, $path);
	$find = 0;
	$path = "";
	my $fileNameNoEndPrefix = "";
	my @impSubs = split(/\./, $import);

	# if input: import android.view.View;
	# may has same name java file, so need check its path
	# the import subs except end sub these will be appear in real java path
	my $bothMach = 0;
	while (@impSubs > 0) {
		my $importEndSub = pop @impSubs;
		my $importRemain = join "/", @impSubs;
		foreach (@$gAllJavaFilePaths) {
			$path = $_;
			$fileNameNoEndPrefix = Util::getFileNameNoEndPrefixByPath($path);
			if ($importEndSub eq $fileNameNoEndPrefix) {
				$bothMach = 1;
				#print __LINE__." may mach: $path\n";
				if ($path !~ m/\/$importRemain\//) {
					#print __LINE__." $importRemain is not mach in $path\n";
					$bothMach = 0;
				}
				if (1 eq $bothMach) {
					$find = 1;
					last;
				}
			}
		}
		if (1 eq $find) { last; }
	}
	return ($find, $path);
}



1;

