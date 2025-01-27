# ffmpeg-chapter-creator
Used to automatically insert chapter metadata into video files using ffmpeg, for use inserting commercial breaks in ErsatzTV (or whatever else you want to do with it!)

Originally this script identified the breaks by detecting silence, but there was too much ambiguity, so now it scans the file for black frames in the video. This is a more resource intensive operation, but it yields much more consistent results. 

# TODO
* Strip old file extension before adding MP4
* Can we clean up filenames more? 
* Update directory traversal to move through subdirectories too. 
* Stretch goal would be to somehow query IMDb for episode summaries etc of the episodes we're scanning....
