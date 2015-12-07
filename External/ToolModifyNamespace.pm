#!/usr/bin/perl;

package ToolModifyNamespace;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( modifyNamespaceWithPaths, modifyNamespaceWithPathsAndExcepts );
use strict;
use BuildNamespace;
use FileOperate;

sub modifyNamespaceWithPaths
{
    my $paths = shift;
    my @empty = ();
	&modifyMacroWithPathsAndExcepts($paths, \@empty);
}

sub modifyNamespaceWithPathsAndExcepts
{
    my $paths = shift;
    my $exceptPaths = shift;
    my @allFilesPaths;
	my $allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".h");
	push @allFilesPaths, @$allFilesPath;
	$allFilesPath = FileOperate::readDirsAndExcepts($paths, $exceptPaths, ".cpp");
	push @allFilesPaths, @$allFilesPath;
	&doModifyNamespace(\@allFilesPaths);
}

sub doModifyNamespace
{
    my $paths = shift;
    foreach my $path (@$paths) {
        my $namespaceSingle = BuildNamespace::buildNamespace($path);
        my @namespaceSubs = split(/::/, $namespaceSingle);
        my @namespaceRevSubs = reverse(@namespaceSubs);
        my $readFileDatas = FileOperate::readFile($path);
        my @writeFileDatas;
        my $needModify = 0;
        my $namespaceBeginIdx = 0;
        my $namespaceEndIdx = 0;

		my @namespaceBeginAim; {
			foreach my $sub (@namespaceSubs) {
				push @namespaceBeginAim, "namespace $sub {\n";
			}
		}

		my @namespaceEndAim; {
			foreach my $sub (@namespaceRevSubs) {
				push @namespaceEndAim, "} // namespace $sub\n";
			}
		}

		my $beginStartIdx = -1;
		my $beginEndIdx = -1;
		my $endStartIdx = -1;
		my $endEndIdx = -1;
		my $line;
        for (my $idx=0; $idx<@$readFileDatas; ++$idx) {
			$line = $readFileDatas->[$idx];
            if ($line =~ m/^namespace\s+(\w+)\s*?{/) {
            	if (-1 eq $beginStartIdx) { $beginStartIdx = $idx; }
                if ($1 ne $namespaceSubs[$namespaceBeginIdx++]) {
                    $needModify = 1;
                }
            }
			else {
				if (-1 eq $beginEndIdx && -1 ne $beginStartIdx) {
					$beginEndIdx = $idx - 1;
				}
			}

            if ($line =~ m/^}\s+\/\/\s+namespace/) {
            	if (-1 eq $endStartIdx) { $endStartIdx = $idx; }
            	if (0 eq $needModify) {
					if ($line =~ m/^}\s+\/\/\s+namespace\s+(\w+)/) {
						if ($1 ne $namespaceRevSubs[$namespaceEndIdx++]) {
                    		$needModify = 1;
                    	}
                	}
                }
            }
            else {
				if (-1 eq $endEndIdx && -1 ne $endStartIdx) {
					$endEndIdx = $idx - 1;
				}
            }
        }
        if (-1 eq $endEndIdx) {
			$endEndIdx = @$readFileDatas - 1;
        }

		if (1 eq $needModify) {
        	if ($beginStartIdx < $endStartIdx) {
        		push @writeFileDatas, @$readFileDatas;
				splice(@writeFileDatas, $endStartIdx, ($endEndIdx-$endStartIdx+1), @namespaceEndAim);
				splice(@writeFileDatas, $beginStartIdx, ($beginEndIdx-$beginStartIdx+1), @namespaceBeginAim);
	            print "--[ToolModifyNamespace.pm:".__LINE__."] namespace file: $namespaceSingle, $path\n";
	            FileOperate::writeFile($path, \@writeFileDatas);
        	}
        	else {
				print "--[ToolModifyNamespace.pm:".__LINE__."] namespace end idx > start idx, failed\n";
        	}
        }
    }
}

1;
