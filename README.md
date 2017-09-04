# MidiFixForSongBeats
Fix MIDI files to be able to play in Yamaha Song Beats for DTX drums


To use on a Linux/Unix/Mac OS computer, download the three ruby scripts `MidiFixForSongBeats.rb`, `mididefs.rb`, and `midifile.rb` into a directory with MIDI files on a computer with ruby installed.  Often ruby is installed by default.  MIDI files may be downloaded from sites like http://www.midiworld.com/ or https://freemidi.org/.

Then run `ruby MidiFixForSongBeats.rb *.mid` to convert all the MIDI files in the current directory.  The fixed files will appear in a sub-directory called `fixed/`.

This works with [Yamaha DTX drums](https://usa.yamaha.com/products/musical_instruments/drums/el_drums/drum_kits/index.html) and [Yamaha Song Beats (app store link)](https://itunes.apple.com/us/app/song-beats/id546319014?mt=8).

The script that I wrote uses [midifile.rb](http://www.goodeveca.net/midifile_rb/) as well as mididefs (adopted from GMlister) taken from this repository released under an open source license.

This script does the following things:

1. Converts to to Format 0 (basically puts everything onto a single midi track).
2. Strips out SysEx Midi messages (System Exclusive) that prevent it from working
3. Strips out all `Program_Change` / `Control_Change` events from channel 10 (Percussion) that sometimes prevent it from working.  (TODO: Figure out which `Program_Change`/`Control_Change` events are fine to keep and leave those in).
4. Renames Track in first `TRACK_NAME` Meta Event to something based on file name, so in the Song Beats app, the files are listed with a readable name instead of something seemingly random like "Guitar" or "Drums" or "tk1". 
5. Doubles Tempo and expands measure for songs under 140 beats, so its easier to see timing.  This can be disabled by specifying the flag `--multiplier 1` .
6. Moves file into subdirectory called 'fixed/' (or custom directory with flag `-o <output_dir>`).
7. Checks that MIDI file has drums in it and don't convert if the midi file has no drums in it.  (This can be over-ridden with `-f` flag).
8. Optionally summarizes drums present in song with custom flag (`-s`).  Note some percussion events do not translate to Song Beats events on a standard drum kit; e.g., Tambourine or Maraca, so this may help you figure out why the MIDI events didn't show up.
