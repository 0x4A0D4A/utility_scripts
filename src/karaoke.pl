#!/usr/bin/env perl
# Script that fetches lyrics for music files from the LRCLIB API and saves them to *.lrc files.

use strict;
use warnings;
use JSON;

sub create_tracklist_from_argv {
    my @tracks;

    foreach my $file_path (@ARGV) {
        if (!-e $file_path) {
            die("$file_path does not exist");
        }
        elsif (-d $file_path) {
            push(@tracks, list_tracks_in_directory($file_path));
        }
        else {
            my $absolute_path = qx(realpath "$file_path");
            chomp($absolute_path);
            push(@tracks, $absolute_path);
        }
    }

    return(@tracks);
}

sub list_tracks_in_directory {
    my ($directory) = @_;

    my @tracks = qx(
        fd --base-directory "$directory" \\
            --type file \\
            --exclude "*.jpg" --exclude "*.png" --exclude "*.lrc" \\
            --absolute-path
    );
    chomp(@tracks);

    if ($? != 0) {
        die("Failed to list tracks in $directory with exit code " . $? >> 8);
    }

    return(@tracks);
}

sub extract_track_metadata {
    my ($track) = @_; 
    print("Extracting metadata from $track\n");

    my @metadata = qx(exiftool -short3 -Title -Artist -Album "$track");
    chomp(@metadata);

    return(@metadata);
}

sub extract_track_duration {
    my ($track) = @_; 
    print("Extracting track duration from $track\n");

    my $duration = qx(ffprobe -loglevel quiet -output_format csv=p=0 -show_entries format=duration "$track");
    chomp($duration);

    # remove the digits after the decimal point
    # the LRCLIB API permits the 'duration' field to be within ±2 seconds of LRCLIB's record, so rounding is unnecessary
    $duration =~ s/\..*//;

    return($duration);
}

sub get_synced_lyrics {
    my ($track_name, $artist_name, $album_name, $duration) = @_;
    my $api_url = "https://lrclib.net/api/search";

    print("Fetching synced lyrics for track $track_name with duration $duration on album $album_name by $artist_name\n");

    my $response = qx(
        curl --get \\
            --data-urlencode "track_name=$track_name" \\
            --data-urlencode "artist_name=$artist_name" \\
            --data-urlencode "album_name=$album_name" \\
            $api_url
        ) or warn("Failed to fetch lyrics data from the API for: "
            . "track_name=$track_name, artist_name=$artist_name, album_name=$album_name"
        ) and return;

    my $lyric_objects = decode_json($response);

    my $best_duration_difference; # variable to store how different the closest duration match found was
    my $best_synced_lyrics; # variable to store the synced lyrics of the closest duration match found

    foreach my $lyric_object (@$lyric_objects) {
        my $synced_lyrics = $lyric_object->{syncedLyrics};

        if (defined $synced_lyrics) {
            my $duration_difference = abs($lyric_object->{duration} - $duration);

            # excluding synced lyrics where the duration is too different from the file we have
            if ($duration_difference < 2 && (!defined $best_duration_difference || $duration_difference < $best_duration_difference)) {
                $best_duration_difference = $duration_difference;
                $best_synced_lyrics = $synced_lyrics;
            }
        }
    }

    return($best_synced_lyrics);
}

sub write_synced_lyrics {
    my ($track, $synced_lyrics, $lyric_file) = @_;
    print("Writing synced lyrics to $lyric_file\n");

    open(my $file_handler, '>:encoding(UTF-8)', $lyric_file)
        or warn("Cannot open $lyric_file") and return;
    print {$file_handler} ($synced_lyrics);
    close($file_handler);
}

sub main {
    my @tracks = create_tracklist_from_argv();

    foreach my $track (@tracks) {
        my $lyric_file = $track =~ s/\.[^.]+$/.lrc/r;
        if (-e $lyric_file) {
            print("$lyric_file already exists\n");
            next;
        }

        my @metadata = extract_track_metadata($track)
            or warn("Failed to extract metadata from $track") and next;
        my ($track_name, $artist_name, $album_name) = @metadata;

        my $duration = extract_track_duration($track)
            or warn("Failed to extract duration from $track") and next;

        my $synced_lyrics = get_synced_lyrics($track_name, $artist_name, $album_name, $duration)
            or warn("Failed to fetch synced lyrics for $track") and next;

        write_synced_lyrics($track, $synced_lyrics, $lyric_file);
    }
}

main();
