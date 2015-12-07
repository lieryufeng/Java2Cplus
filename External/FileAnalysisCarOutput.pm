#!/usr/bin/perl;

package FileAnalysisCarOutput;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use warnings;
use PDF::API2;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;
use TransElastosType;

our $TAB = "    ";

sub outputCar_AnalisisStructsOntoConsole
{
	my $roots = shift;

	my $cnt = @$roots;
	print __LINE__." outputCar_AnalisisStructsOntoConsole start, \$cnt=$cnt\n";
	foreach my $item (@$roots) {
		$item->testOutputStruct("");
		print "\n";
	}
	print __LINE__." outputCar_AnalisisStructsOntoConsole end\n";
}

sub outputCar_AnalisisStructsOntoPdf
{
	my $roots = shift;

	my $pdf = PDF::API2->new;
	$pdf->mediabox('A4');
	foreach my $item (@$roots) {
		&outputCar_Interface($item, $pdf);
	}
	$pdf->saveas('CarsInfo.pdf');
}

sub outputCar_Interface
{
	my $root = shift;
	my $pdf = shift;

	# 0,0 is leftbottom, after testing max is 550,810
	my $maxX = 550;
	my $maxY = 810;
	my $startX = 10;
	my $startY = $maxY;
	my $startSpace = "";
	&outputCar_InterfaceLoop($root, $pdf, $startSpace);
}

sub outputCar_InterfaceLoop
{
	my $root = shift;
	my $pdf = shift;
	my $startSpace = shift;

	my $ft = $pdf->cjkfont('Song');
	my $page = $pdf->page;
	my $gfx = $page->gfx;
	my $name = $root->{ $FileTag::K_NodeName };

	&resetPos;
	my ($startX, $startY) = &getPos;
	$gfx->textlabel($startX, $startY, $ft, 20, "$name");

	$startSpace = $startSpace."    ";
	my $children = $root->{ $FileTag::K_SubNodes };
	foreach my $item (@$children) {
		if ("FUNC" eq $item->{ $FileTag::K_NodeType }) {
			my $funcName = $item->{ $FileTag::K_NodeName };
			my $params = $item->{ $FileTag::K_SubNodes };
			if (@$params > 0) {
				($startX, $startY) = &getPos;
				$gfx->textlabel($startX, $startY, $ft, 10, $startSpace."$funcName(");

				$startSpace = $startSpace."    ";
				for (my $idx=0; $idx<@$params; ++$idx) {
					my $parm = $params->[$idx];
					my $inOutType = $parm->{ $FileTag::K_ParamInOutType };
					my $parmType = $parm->{ $FileTag::K_ParamType };
					my $parmName = $parm->{ $FileTag::K_ParamName };
					if ($idx ne @$params-1) {
						($startX, $startY) = &getPos;
						$gfx->textlabel($startX, $startY, $ft, 10, $startSpace."$inOutType $parmType $parmName,");
					}
					else {
						($startX, $startY) = &getPos;
						$gfx->textlabel($startX, $startY, $ft, 10, $startSpace."$inOutType $parmType $parmName);");
					}
				}
			}
			else {
				($startX, $startY) = &getPos;
				$gfx->textlabel($startX, $startY, $ft, 10, $startSpace."$funcName();");
			}
		}
	}
}

my $gStartX = 10;
my $gStartY = 810;
my $gMaxX = 550;
my $gMaxY = 810;
sub getPos
{
	my ($startX, $startY) = ($gStartX, $gStartY);
	$gStartY -= 30;
	if ($gStartY < 10) {
		$gStartX = 10;
		$gStartY = 810;
	}
	return ($startX, $startY);
}

sub resetPos
{
	$gStartX = 10;
	$gStartY = 810;
}



1;

