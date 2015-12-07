#!/usr/bin/perl;

package ToolFindOutParamHasRefAdd;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use FileOperate;

sub findOutParamHasRefAddWithPaths {
    my $paths = shift;
    print __LINE__." into findOutParamHasRefAddWithPaths\n";
    my @empty = ();
    my $allFilesPath = FileOperate::readDirsAndExcepts($paths, \@empty, ".cpp");
	foreach my $filePath (@$allFilesPath) {
		&findOutParamHasRefAddWithPath($filePath);
	}
}

sub findOutParamHasRefAddWithPath {
    my $path = shift;
	my $fileLines = FileOperate::readFile($path);
    my $findOutParam = 0;
    my @matchInfos = ();
    my @outParams = ();
    my %eachFuncOutParams = ();
    my $inFunc = 0;

    for (my $idx=0; $idx<@$fileLines; ++$idx) {

    	my $line = $fileLines->[$idx];
        if ($line =~ m/\[out\]/ && $line =~ m/\*\*/ && $line =~ m/\*\*\s*(\d+|\w+)/) {
			#print __LINE__." find outparam: $line";

        	my $outParam = $1;
        	my %outParamInfo = ();
        	$outParamInfo{ "LineNumber" } = $idx + 1;
			$outParamInfo{ "OutParam" } = $outParam;
        	push @outParams, \%outParamInfo;
            $findOutParam = 1;

			my %paramInfo = ();
			$paramInfo{ "LineNumber" } = $idx + 1;
			$paramInfo{ "LineData" } = $line;
            $eachFuncOutParams{ $idx + 1 } = \%paramInfo;

            #print __LINE__." match [out]\n";
        }
        elsif (1 eq $findOutParam && $line =~ m/^\{$/) {
        	$inFunc = 1;
        	#print __LINE__." find {: $line";
        }
        elsif (1 eq $findOutParam && 1 eq $inFunc && $line =~ m/^\}$/) {
        	#print __LINE__." find }: $line";
        	$findOutParam = 0;
        	$inFunc = 0;
        	@outParams = ();
    		%eachFuncOutParams = ();
        }
        elsif (1 eq $findOutParam && 1 eq $inFunc) {
        	#print __LINE__." in func: $line";

        	foreach my $param (@outParams) {
        		my $outParam = $param->{ "OutParam" };
        		my $outParamLine = $param->{ "LineNumber" };
				if ($line =~ m/^\s*\*$outParam\s*=/ && $line !~ m/^\s*\*$outParam\s*=\s*NULL/) {

					#print __LINE__." \$outParam=$outParam, \$outParamLine=$outParamLine\n";
					my $nextLine = $fileLines->[$idx + 1];
					if ($nextLine !~ m/^\s*REFCOUNT_ADD\(\*$outParam\)/) {
						if (exists ($eachFuncOutParams{ $outParamLine })) {
							my $paramInfo = $eachFuncOutParams{ $outParamLine };
							push @matchInfos, $paramInfo;
						}
						else {
							print __LINE__." out param donot match, check it\n";
							sleep 10;
						}
					}
				}
        	}
        }
        else {
			#print __LINE__." into else: $line";
        }
    }

    if (@matchInfos > 0) {
    	print __LINE__."\n";
		print __LINE__." find OutParams has no REFCOUNT_ADD: \n$path\n";
		my $lineNumber = 0;
		my $lineData;
		foreach my $item (@matchInfos) {
			$lineNumber = $item->{ "LineNumber" };
			$lineData = $item->{ "LineData" };
			print __LINE__." [ln: $lineNumber]: $lineData";
		}
    }
}

1;



