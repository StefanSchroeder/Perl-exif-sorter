# 
#  exif-sorter.pl
# 
#  A simple tool to organize images.
#
#  Written by Stefan Schroeder, 2013-01-12 in New York.
#
#  Copyright 2013 Stefan Schroeder
# 
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# 
#
# I promise to add POD one day.
#
# if file already exists: if files are identical, ignore new file
#                         if files differ, rename new file and append md5 to filename.

use strict;
use File::Find;
use File::Copy;
use File::Spec;
use File::Basename;
use Image::ExifTool;
use File::Path qw(make_path);
use Cwd;
use Digest::MD5;

my $verbose = 1;
my $copy_strategy = "copy";
my $unknown_strategy = "leave_alone"; # can be leave_alone or copy or move

my $OUT_DIR = getcwd;

die("Nothing to do.") unless (@ARGV);

my $exifTool = new Image::ExifTool;
$exifTool->Options(Unknown => 1);

my @directories_to_search = @ARGV;

find(\&wanted, @directories_to_search);

exit;

sub wanted 
{ 
	if ((m/\.jpe?g/i) || (m/\.mov/i) || (m/\.3gp/i) )
	{
		my $n = $File::Find::name;
		my ($yy, $mm) = get_info($n);
		#print "$n -> $yy, $mm\n";
		# if directory does not exist make dir for year and for month
		my $month_dir = File::Spec->catdir($OUT_DIR, $yy, $mm);
		my $abs_path = File::Spec->rel2abs( $month_dir ) ;

		make_path($abs_path);

		process($n, $abs_path, $mm);
	}
}

sub process
{
	my $fullfilename = shift;
	my $dir = shift;
	my $month = shift; # can be unknown

	my $bn = basename($fullfilename);

	my $target_filename = File::Spec->catdir($dir, $bn); # absolute
	if (-e $target_filename)
	{
		my $md5 = getMD5($fullfilename);
		$fullfilename =~ m/(.*)\.(.*)/;

		my ($prefix, $suffix) = ($1, $2);
		$target_filename = $prefix . ".chksum." . $md5 . "." . $suffix;
	}
	
	if($verbose)
	{
		warn "copy($fullfilename, $target_filename)\n"
	}

	if ($copy_strategy eq "copy")
	{
		copy($fullfilename, $target_filename);
	}
	elsif ($copy_strategy eq "move")
	{
		move($fullfilename, $target_filename);
	}
}

sub getMD5
{
	my $f = shift;
	open(my $FILE, $f) or die "Can't open '$f': $!";
	binmode($FILE);
	my $md5 = Digest::MD5->new->addfile(*$FILE)->hexdigest, " $f\n";
	close($FILE);
	return ($md5);
}

sub get_info
{
	my $name = shift;
	my $y = "unknown";
	my $m = "unknown";

	my $info = $exifTool->ImageInfo($name);
	my $group = '';
	foreach my $tag ($exifTool->GetFoundTags('Group0')) 
	{
		if ($group ne $exifTool->GetGroup($tag)) 
		{
			$group = $exifTool->GetGroup($tag);
			#print "---- $group ($tag)----\n";
		}
		my $val = $info->{$tag};
		if (ref $val eq 'SCALAR') {
			if ($$val =~ /^Binary data/) {
				$val = "($$val)";
			} else {
				my $len = length($$val);
				$val = "(Binary data $len bytes)";
			}
		}
		my $h = $exifTool->GetDescription($tag);
		if ($h eq "Create Date")
		{
			my ($exifdate, $exiftime) = split(" ", $val);
			#print "Date=$exifdate Time=$exiftime\n";
			($y, $m) = split(":", $exifdate);
			#printf("%-32s : %s\n", $h, $val);
		}
	}
	return ($y, $m);
}

