# MidiFixForSongBeats

## Fix MIDI files to be able to play in Yamaha Song Beats for DTX drums

To use on a Linux/Unix/Mac OS computer, download the three ruby scripts [`MidiFixForSongBeats.rb`](https://raw.githubusercontent.com/drjimbob/MidiFixForSongBeats/master/MidiFixForSongBeats.rb), [`mididefs.rb`](https://raw.githubusercontent.com/drjimbob/MidiFixForSongBeats/master/mididefs.rb), and [`midifile.rb`](https://raw.githubusercontent.com/drjimbob/MidiFixForSongBeats/master/midifile.rb) into a directory with MIDI files on a computer with ruby installed.  Often ruby is installed by default.  MIDI files may be downloaded from sites like http://www.midiworld.com/ or https://freemidi.org/.

This has not been tested on a windows computer, but in principle the script should work after installing ruby (possibly you'll need minimal changes to deal with file paths operating differently in windows).

Then run `ruby MidiFixForSongBeats.rb *.mid` to convert all the MIDI files in the current directory.  The fixed files will appear in a sub-directory called `fixed/`.

This works with [Yamaha DTX drums](https://usa.yamaha.com/products/musical_instruments/drums/el_drums/drum_kits/index.html) and [Yamaha Song Beats (app store link)](https://itunes.apple.com/us/app/song-beats/id546319014).

The script that I wrote uses [midifile.rb](http://www.goodeveca.net/midifile_rb/) as well as mididefs (adopted from GMlister) taken from this repository released under an open source license.

## What the MidiFixForSongBeats.rb Script Does

1. Converts to to Format 0 (basically puts everything onto a single midi track).
2. Strips out SysEx Midi messages (System Exclusive) that prevent it from working
3. Strips out all `Program_Change` / `Control_Change` events from channel 10 (Percussion) that sometimes prevent it from working.  (TODO: Figure out which `Program_Change`/`Control_Change` events are fine to keep and leave those in).
4. Renames Track in first `TRACK_NAME` Meta Event to something based on file name, so in the Song Beats app, the files are listed with a readable name instead of something seemingly random like "Guitar" or "Drums" or "tk1". 
5. Doubles Tempo and expands measure for songs under 140 beats, so its easier to see timing.  This can be disabled by specifying the flag `--multiplier 1` .
6. Moves file into subdirectory called 'fixed/' (or custom directory with flag `-o <output_dir>`).
7. Checks that MIDI file has drums in it and don't convert if the midi file has no drums in it.  (This can be over-ridden with `-f` flag).
8. Optionally summarizes drums present in song with custom flag (`-s`).  Note some percussion events do not translate to Song Beats events on a standard drum kit; e.g., Tambourine or Maraca, so this may help you figure out why the MIDI events didn't show up.

## How to load Midi files into Song Beats on the iPad/iPhone.

You can do this using Itunes.  You can follow this [youtube video](https://www.youtube.com/watch?v=1Pq42dAKwYM) I found.  The steps are basically:

1. Install [Song Beats](https://itunes.apple.com/us/app/song-beats/id546319014) onto the iPad/iPhone if it's not already installed.  Please note if you don't see it in the app store that SongBeats is listed as an iPhone only application.  So make sure you are not only searching for iPad only apps (or search for iPhone only apps on your iPad). 
2. Connect the iPad up to your computer with a USB-to-ipad (lightning for new iPads/30-pin connector for older iPads).
3. Open up iTunes.
4. Click the iPad/iPhone shaped icon that's next to the drop down menu in the upper left:
![iPad/iPhone Icon Button in iTunes](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/mac_apps/itunes/macos-itunes12-5-device-callout.jpg "iPad/iPhone Icon Button in iTunes")
5. In the left-sidebar, select "Apps".
6. In the main window, then scroll to the bottom to see the File Sharing section. ![File Sharing Section](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/mac_apps/itunes/macos-itunes12-5-apps-file-sharing.jpg "File Sharing Section")
7. Select Song Beats and then drag-and-drop the fixed midi files into this directory.

## How to connect DTX to iPad/iPhone

The [DTX expects a USB-B connection to the iPad/iPhone lightning (or 30-pin connector for older iPad/iPhones)](http://faq.yamaha.com/us/en/article/musical-instruments/drums/el-drumkit/dtx400/10326/8395).   I use a printer cable (USB-A to USB-B) [similar to this one on amazon](https://smile.amazon.com/AmazonBasics-USB-2-0-Cable-Male/dp/B00NH11KIK/) and use it with the [apple lightning to USB adapter](https://www.apple.com/shop/product/MD821AM/A/lightning-to-usb-camera-adapter) like [here it is on amazon](https://www.amazon.com/gp/product/B014VGHG0U/).  I've also tried a cheaper lightning to USB connector like [this one on amazon](https://www.amazon.com/gp/product/B00W57CUAE/) however I do not recommend the cheaper one.  When I connected it to my DTX 4xx module, it would work for about a minute or so (long enough to transfer files using MusicSoft Manager app to save in one of 10 memory banks), but then it presents with an error message saying "This device is not supported by this iPad" (and then I have to reconnect the cables and it will usually work again for a little bit after a few tries).  Meanwhile with the expensive Apple adapter, I haven't gotten an error message yet after a lot more use. 

## What's the deal with `midifile_rb.tgz` and the `MIDIFILE_RB` directory in this repository?

The parsing of a midi file is being done using the ruby library `midifile.rb` that is available at [`http://www.goodeveca.net/midifile_rb/`](http://www.goodeveca.net/midifile_rb/) and written by someone else.  The files inside the `MIDIFILE_RB` directory are not required for this to work (you only need `MidiFixForSongBeats.rb`, `midifile.rb` and `mididefs.rb`, however the license of the required  `midifile.rb` (see `MIDIFILE_RB/README`) specifies they be distributed along with the file.

>midifile.rb may be freely copied in its entirety provided that this notice, all source code, all documentation, and all other files are included.
