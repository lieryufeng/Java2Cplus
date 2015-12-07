#!/usr/bin/perl;

# package name must be equal to file name.
=pod windows
BEGIN {
	push @INC, "E:/self/program/perl/JavaToCplus_by_pm";
	push @INC, "E:/self/program/perl/JavaToCplus_by_pm/External";
}
=cut

#=pod ubuntu
BEGIN {
    unshift @INC, $ENV{"PWD"};
    unshift @INC, $ENV{"PWD"}."/External";
}
#=cut

use Cwd;
use strict;
use FileAnalysisCar;
use FileAnalysisCarPolish;
use FileAnalysisCarOutput;

my $ret = &main;

sub main
{
    &buildPdfFromCar;
    return 0;
}

sub buildPdfFromCar
{
	my $docs = FileAnalysisCar::analysisAllCar;
	my $cnt = @$docs;
	print __LINE__." after analysisCar: \$cnt=$cnt\n";
	my $newDocs = FileAnalysisCarPolish::polishAnalisisStructs($docs);
	$cnt = @$newDocs;
	print __LINE__." after polish: \$cnt=$cnt\n";
	FileAnalysisCarOutput::outputAnalisisStructsOntoConsole($newDocs);
	FileAnalysisCarOutput::outputAnalisisStructsOntoPdf($newDocs);
}


