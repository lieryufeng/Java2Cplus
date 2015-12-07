#!/usr/bin/perl;

my $ret = &TransTagDefineToTagHash;

sub TransTagDefineToTagHash
{
	my $srcFile = "./tag_define.pl";
	my $dstFile = "./tag_hash.pl";

	open (FILE, "<", $srcFile) || die "cannot open the file $srcFile.\n";
	my @lines = <FILE>;
	close FILE;

	open (FILE, ">", $dstFile) || die "cannot open the file $dstFile.\n";
	{
		print FILE ("#!/usr/bin/perl\n");
		print FILE ("\n");
		print FILE ("require(\"./tag_define.pl\");\n");
		print FILE ("\n");
		print FILE ("# varible string and tag info\n");
		print FILE ("my \%DC_Idx2Str;\n");
		print FILE ("\n");
		foreach my $line (@lines)
		{
			next if ($line =~ m/^#!/);
			if ($line =~ m/^#/) 
			{
				print FILE ("$line");
			}
			elsif ($line =~ m/^my\s+(\$DC_\w+)/) 
			{
				my $tmp0 = $1;
				my $tmp1 = $1;
				$tmp1 =~ s/^\$//;
				print FILE ("\$DC_Idx2Str{$tmp0} = \"$tmp1\";\n");
			}
		}
	}	
	close FILE;
}