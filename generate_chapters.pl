#!/usr/bin/env perl
$| = 1;
use 5.010;
use Data::Dumper;
use Capture::Tiny qw/capture/;

$removestr='text_to_remove_from_title';
$dirpath='/home/nick/media/shows/';
opendir DIR,$dirpath;
my @fname_list = readdir(DIR);
close DIR;

foreach $fname (@fname_list)
{
	@breaks = (); #Will include two entries for 1 and $length to make chapter parsing smoother in the generate_metadata subroutine.
	push(@breaks, 1);
	next if $fname eq '.' || $fname eq '..';
	say "###########################################################################################\n";
	say "##### STARTING: $fname #####\n";
	say "###########################################################################################\n";

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
		push(@breaks, $break);
	}
	push(@breaks, $length);

	print("\nGenerating metadata file....\n");
	$newname = $fname;
	$newname =~ s/$removestr//;

	generate_metadata($newname, \@breaks);
	exit 0;
}

sub generate_metadata
{
	$filename   = @_[0];
	@chapters   = @{$_[1]};
	
	$num_chapters = scalar @chapters;

	open $fh, '>', "$filename.md";
	print {$fh} ";FFMETADATA1\n";
	print {$fh} "title=$filename\n";
	print {$fh} "\n";

	for(my $i = 0; $i < $#chapters; $i++)
	{
		print {$fh} "[CHAPTER]\n";
		print {$fh} "TIMEBASE=1/1000\n";
		print {$fh} "START=$chapters[$i]\n";
		$nextchap = $chapters[$i+1] - 1;
		print {$fh} "END=$nextchap\n";
		print {$fh} "\n";
	}

	close $fh;
}

