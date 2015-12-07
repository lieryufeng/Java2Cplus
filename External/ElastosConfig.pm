#!/usr/bin/perl;

package ElastosConfig;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );
use strict;
use FileOperate;

# Rule: path end has no '/'
our $CFG_ELASTOS_BASE = "/home/lieryufeng/self/program/__work__/ElastosRDK5_0";
our $CFG_ELASTOS_INC_BASE = $CFG_ELASTOS_BASE."/Sources/Elastos/Frameworks/Droid/Base/Core/inc";
our $CFG_ELASTOS_LIBCORE_INC = $CFG_ELASTOS_BASE."/Sources/Elastos/LibCore/inc";

# android path, really android project files path
our $CFG_ANDROID_BASE = "/home/lieryufeng/self/program/__work__/Android5_0_2_Actions";
our $CFG_ANDROID_FRAME_BASE = $CFG_ANDROID_BASE."/android/frameworks";
our $CFG_ANDROID_LIBCORE_BASE = $CFG_ANDROID_BASE."/android/libcore";

our $CFG_ANDROID_IMP_ORG_BASE = $CFG_ANDROID_BASE."/android/external/chromium_org";
our $CFG_ANDROID_IMP_ANDROID = $CFG_ANDROID_FRAME_BASE."/base/core/java/android";
our $CFG_ANDROID_IMP_COM = $CFG_ANDROID_FRAME_BASE."/base/core/java/com";
our $CFG_ANDROID_IMP_JAVA = $CFG_ANDROID_LIBCORE_BASE."/luni/src/main/java/java";
our $CFG_ANDROID_IMP_JAVAX = $CFG_ANDROID_LIBCORE_BASE."/luni/src/main/java/javax";

sub getElastosBaseDir
{
	return $CFG_ELASTOS_BASE;
}

sub getElastosIncSubModulesName
{
	my $modulesNames = FileOperate::readDirSubFoldersNoRecursive($CFG_ELASTOS_INC_BASE);
	return $modulesNames;
}

sub getElastosLibcoreInc
{
	return $CFG_ELASTOS_LIBCORE_INC;
}


1;