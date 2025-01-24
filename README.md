# ffmpeg-chapter-creator
Used to automatically insert chapter metadata into video files using ffmpeg, for use inserting commercial breaks in ErsatzTV (or whatever else you want to do with it!)

# TODO
Pseudocode for script is as follows:
* Provide name of directory, and name of files within that directory (TODO automatically scan files in directory.)
* Provide the string to remove from the filename (any text from the filename that you do not wish to include in the final file.)
* Iterate through each file running an ffmpeg scan to identify silences (was way less time and CPU intensive than scanning for black frames, and easier than accounting for grey-outs instead of full blackouts)
* Filter output for relevant silence time blocks in seconds, put that info in input-file-specific metadata file
* Figure out how to dynamically convert the timestamps in the above output file to a format ffmpeg metadata understands
* Build episode-specific metadata file with chapters and title
* Encode input file with that metadata file, and generate a name for the output file with any desired text from above removed. 

