#!/usr/bin/env perl
$| = 1;
use 5.010;
use Capture::Tiny qw/capture/;

$oldext='.mp4'; #re-encoded as mp4 to include chapter metadata. Remove old file extensions. (Include even if source is MP4 - see code below.)
$removestr='';

$root_path="/path/to/media";
opendir RDIR,$root_path;
my @subdir_list = readdir(RDIR);
close RDIR;

$start_pct=0;
$total_pct=`find '$root_path' -type f | wc -l`;

foreach $sname (sort @subdir_list) #{ $a <=> $b } @subdir_list)
{
	next if $sname eq '.' || $sname eq '..';

	$subdir_path = $root_path.'/'.$sname;
	opendir DIR,$subdir_path;
	my @fname_list = readdir(DIR);
	close DIR;

	#Create subdirectory in the output folder to correspond to this directory. 
	mkdir("/mnt/cephfs/output/$sname");

	foreach $fname (sort @fname_list) # (sort { $a <=> $b } @fname_list)
	{
		next if $fname eq '.' || $fname eq '..';
		
		$start_pct++;
		$pct = ($start_pct / $total_pct) * 100;
		$pct_str = "(" .  sprintf("%.1f", $pct) . '%)';
		my $padchar = '#';
		my $padlen = (128 - length($fname)) / 2; #128 instead of 130 to account for the two hardcoded spaces in $padded_title
		my $padded_title = ($padchar x ($padlen - ($padlen % 2))) . " " . $fname . " " . ($padchar x $padlen) . " $pct_str";

		say($padchar x 130);
		say($padded_title);
		say($padchar x 130);

		say("Scanning for black frames...");
		my ($out, $err) = capture {
			system("ffmpeg -i \"$subdir_path/$fname\" -vf blackdetect=d=0.1:pix_th=.1 -f rawvideo -y /dev/null");
		};

		$err =~ s/\r/\n/g; #Converting carriage returns to newlines.
		@lines = split(/\n/, $err);

		$length = `ffprobe -i "$subdir_path/$fname" -show_format -v quiet | grep duration | cut -d= -f2`;
		$length =~ s/\n//;

		@breaks = ();
		push(@breaks, 0);

		foreach (@lines) {
			#Parse the timestamp (in seconds) where blackness starts and ends, and how long it lasts
			$_ =~ /.*black_start:([0-9\.]+) black_end:([0-9\.]+) black_duration:([0-9\.]+)/ || next;
			my ($start, $end, $duration) = ($1, $2, $3);

			#Skip darkness if in first 5 minutes (theme song), less than 1 second (scene change), or within 4 minutes of end (credits)
			next if $start < 480;
			next if	$duration < 0.251; 
			next if $length - $start < 420;
			next if ($start - ($breaks[-1]/1000) < 300); #Skip if we just flagged a commercial in the past 5 minutes.  
			
			say("Start: $start | End: $end | Duration $duration");
			my $break = $start + (($end-$start)/2);
			say("Proposed break time: $break");
			push(@breaks, $break*1000); #Chapter data cuts off decimal so we do 1000X and use 1/1000 Timebase
		}
		push(@breaks, $length*1000);

		say("\nGenerating metadata file....");
		#Any other name translations needed should be done here. 
		$newname = $fname;
		$newname =~ s/^$removestr//;
		$newname =~ s/\'//g;
		$newname =~ s/\"//g;
		$newname =~ s/$oldext//;
		#$newname =~ s/([0-9]+)x([0-9]+) - (.*)/$3 - s$1e$2/; #Directory-specific transformation to enable ErsatzTV to parse season/episode data
		say("    Name:     $newname.mp4");
		say("    Chapters: " . join(', ', @breaks));

		if (scalar @breaks == 2)
		{
			say("\nNo chapters found in $fname. File will be re-encoded without chapters.");
			system("ffmpeg -v quiet -i \"$subdir_path\/$fname\" -codec copy \"/mnt/cephfs/media-scratch/output/$sname/$newname.mp4\"");
		}
		else
		{
			say("\nRe-encoding $newname with chapter metadata...");
			generate_metadata($newname, \@breaks);
			system("ffmpeg -v quiet -i \"$subdir_path\/$fname\" -i \"./md/$newname.md\" -codec copy -map_metadata 1 -map_chapters 1 \"/mnt/cephfs/media-scratch/output/$sname/$newname.mp4\"");
		}
		print("\n");
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
