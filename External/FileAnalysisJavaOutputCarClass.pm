#!/usr/bin/perl;

package FileAnalysisJavaOutputCarClass;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( outputCarClassAnalisisStruct, outputCarClassRoot );
use strict;
use warnings;
use FileOperate;
use FileAnalysisStruct;
use FileTag;
use Util;
use TransElastosType;

our $TAB = "    ";
our $gCurrDotHRoot;

sub outputCarClassAnalisisStruct
{
	my $dotHRoot = shift;
	my $dotCppRoot = shift;
	my $filePath = $dotHRoot->{ $FileTag::K_NodeName };
	my $dotHPath = $filePath;

	my @subs = split(/\//, $dotHPath);
	my $lastSub = $subs[$#subs];
	$lastSub =~ s/\.java$/\.h/;
	$lastSub = "C".$lastSub;
	$subs[$#subs] = $lastSub;
	$dotHPath = join "/", @subs;
	$dotHPath = "/".$dotHPath;

	my $dotCppPath = $dotHPath;
	$dotCppPath =~ s/\.h$/\.cpp/;
	my ($dotHContext, $dotCppContext) = &outputCarClassRoot($dotHRoot, $dotCppRoot);
	FileOperate::writeFile($dotHPath, $dotHContext);
	FileOperate::writeFile($dotCppPath, $dotCppContext);
	if (1 eq &outputCarClassCppControl($dotCppRoot)) {

	}
	else {
		unlink $dotCppPath;
		print __LINE__." noneedcpp: $dotCppPath\n";
	}
}

sub outputCarClassRoot
{
	my $dotHRoot = shift;
	my $dotCppRoot = shift;
	$gCurrDotHRoot = $dotHRoot;
	my @dotHContexts = ();
	my @dotCppContexts = ();

	#push @dotHContexts, "// wuweizuo automatic build .h file from .java file.\n";
	#push @dotCppContexts, "// wuweizuo automatic build .cpp file from .java file.\n";
	my $startSpace = "";
	# .h
	{
		my $childs = $dotHRoot->{ $FileTag::K_SubNodes };
		foreach (@$childs) {
			&outputCarClassContext($_, \@dotHContexts, 0, $startSpace);
		}
	}
	# .cpp
	{
		my $childs = $dotCppRoot->{ $FileTag::K_SubNodes };
		foreach (@$childs) {
			&outputCarClassContext($_, \@dotCppContexts, 1, $startSpace);
		}
	}

	push @dotHContexts, "\n";
	push @dotCppContexts, "\n";
	return (\@dotHContexts, \@dotCppContexts);
}

sub outputCarClassContext
{
	my $item = shift;
	my $dotContexts = shift;
	my $dotHCpp = shift;
	my $startSpace = shift;

	if (!exists ($item->{ $FileTag::K_NodeTag })) {
		return $dotContexts;
	}

	my $tag = $item->{ $FileTag::K_NodeTag };
	# line
	&outputCarClassEmpty($tag, $item, $dotContexts, $dotHCpp, $startSpace);

	# marco define

	if (FileTag::isTagValid($tag)) {
		if ($FileTag::DC_empty eq $tag) {
    		&outputCarClassEmpty($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_class eq $tag) {
    		&outputCarClassClass($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_namespace_start eq $tag) {
			&outputCarClassNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_namespace_end eq $tag) {
			&outputCarClassNamespace($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_macro_start eq $tag) {
			&outputCarClassMarco($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_macro_end eq $tag) {
			&outputCarClassMarco($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
    	elsif ($FileTag::DC_include eq $tag) {
			&outputCarClassInclude($tag, $item, $dotContexts, $dotHCpp, $startSpace);
    	}
	}

	return $dotContexts;
}

sub dotH
{
	my $defineMacro = shift;
	my $midCarClassDotHFile = shift; # such as: _Elastos_Droid_Widget_CChronometer.h
	my $cplusplusClassDotHFile = shift; # such as: elastos/droid/widget/Chronometer.h
	my @contexts = ();
	push @contexts, "\n";
	push @contexts, "#ifndef $defineMacro\n";
	push @contexts, "#define $defineMacro\n";
	push @contexts, "\n";
	push @contexts, "#include \"$midCarClassDotHFile\"";
	push @contexts, "#include \"$cplusplusClassDotHFile\"";
	push @contexts, "\n";
namespace Elastos {
namespace Droid {
namespace Widget {

CarClass(CChronometer)
    , public Chronometer
{
public:
    CAR_OBJECT_DECL()
};

} // namespace Widget
} // namespace Droid
} // namespace Elastos

#endif // __ELASTOS_DROID_WIDGET_CCHRONOMETER_H__


}


1;

