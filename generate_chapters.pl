#!/usr/bin/env perl
$| = 1;
use 5.010;
use Capture::Tiny qw/capture/;

$oldext='.avi'; #re-encoded as mp4 to include chapter metadata. Remove old file extensions. (Include even if source is MP4 - see code below.)
$removestr='string_to_remove';

$dirpath='/path/to/source/directory';
opendir DIR,$dirpath;
my @fname_list = readdir(DIR);
close DIR;

foreach $fname (@fname_list)
{
	@breaks = ();
	push(@breaks, 0);
	next if $fname eq '.' || $fname eq '..';
	print "###########################################################################################\n";
	print "##### STARTING: $fname #####\n";
	print "###########################################################################################\n";

	my ($out, $err) = capture {
		system("ffmpeg -i \"$dirpath/$fname\" -vf blackdetect=d=0.1:pix_th=.1 -f rawvideo -y /dev/null");
	};

	$length = `ffprobe -i "$dirpath/$fname" -show_format -v quiet | grep duration | cut -d= -f2`;
	$length =~ s/\n//;

	#Convert carriage returns to newlines
	$err =~ s/\r/\n/g;

	@lines = split(/\n/, $err);
	foreach (@lines) {
		#Parse the timestamp (in seconds) where blackness starts and ends, and how long it lasts
		$_ =~ /.*black_start:([0-9\.]+) black_end:([0-9\.]+) black_duration:([0-9\.]+)/ || next;
		my ($start, $end, $duration) = ($1, $2, $3);

		#Skip darkness if in first 5 minutes (theme song), less than 1 second (scene change), or within 4 minutes of end (credits)
		next if $start < 360;
		next if	$duration < 1.0; 
		next if $length - $start < 300;
		
		print("Start: $start | End: $end | Duration $duration\n");
		my $break = $start + (($end-$start)/2);
		print("Proposed break time: $break\n");
		push(@breaks, $break*1000); #Chapter data cuts off decimal so we do 1000X and use 1/1000 Timebase
	}
	push(@breaks, $length*1000);

	print("\nGenerating metadata file....\n");
	#Any other name translations needed should be done here. 
	$newname = $fname;
	$newname =~ s/$removestr//;
	$newname =~ s/\'//;
	$newname =~ s/\"//;
	$newname =~ s/$oldext//;
	$newname =~ s/\[([0-9]+)\-([0-9]+)\] (.*)/$3 - s$1e$2/; #Directory-specific transformation to enable ErsatzTV to parse season/episode data

	if (scalar @breaks == 2)
	{
		print("No chapters found in $fname. File will not be renamed, and no metadata generated.");
	}
	else
	{
		generate_metadata($newname, \@breaks);
		system("ffmpeg -v quiet -i \"$dirpath\/$fname\" -i \"./md/$newname.md\" -codec copy -map_metadata 1 -map_chapters 1 \"./output/$newname.mp4\"");
	}
}

sub generate_metadata
{
	$filename   = @_[0];
	@chapters   = @{$_[1]};
	
	$num_chapters = scalar @chapters;

	open $fh, '>', "./md/$filename.md";
	print {$fh} ";FFMETADATA1\n";
	print {$fh} "title=$filename\n";
	print {$fh} "\n";

	for(my $i = 0; $i < $#chapters; $i++)
	{
		print {$fh} "[CHAPTER]\n";
		print {$fh} "TIMEBASE=1/1000\n";
		print {$fh} "START=$chapters[$i]\n";
		print {$fh} "END=$chapters[$i+1]\n";
	}

	close $fh;
}
