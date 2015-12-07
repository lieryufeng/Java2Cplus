#!/usr/bin/perl;

package BuildNamespace;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( buildNamespaces, buildNamespace, buildNamespaceStartList, buildNamespaceEndList );
use strict;
use Util;
use FileOperate;
use BuildElastosPath;
use ToolDealImports;

sub buildNamespaces {
    my $filePaths = shift;
    my @namespaces;
    foreach my $path (@$filePaths) {
        push @namespaces, &buildNamespace($path);
    }
    return \@namespaces;
}

sub buildNamespace {
    my $filePath = shift;
    my $namespace = BuildElastosPath::buildElastosPath($filePath);
    $namespace =~ s/_/::/g;
    return $namespace;
}

sub buildNamespaceStartList
{
	my $filePath = shift;
	my $namespaceSingle = &buildNamespace($filePath);

	my @namespaceSubs = split(/::/, $namespaceSingle);
	my @namespaceBeginAim; {
		foreach my $sub (@namespaceSubs) {
			push @namespaceBeginAim, "namespace $sub {\n";
		}
	}
	return \@namespaceBeginAim;
}

sub buildNamespaceEndList
{
	my $filePath = shift;
	my $namespaceSingle = &buildNamespace($filePath);

	my @namespaceSubs = split(/::/, $namespaceSingle);
	my @namespaceRevSubs = reverse(@namespaceSubs);
	my @namespaceEndAim; {
		foreach my $sub (@namespaceRevSubs) {
			push @namespaceEndAim, "} // namespace $sub\n";
		}
	}
	return \@namespaceEndAim;
}

sub buildUsingnspaces
{
	my $root = shift;
	my @usingNamespaces = ();
	#ToolDealImports::buildUsingnspacesByImport($root, \@usingNamespaces);
    return \@usingNamespaces;
}


1;
