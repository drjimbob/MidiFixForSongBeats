#! /usr/bin/env ruby

# Convert Midi to Format friendly for Yamaha Song Beats
# Specifically for DTX drums
# 1. Converts from Midi Format 0 to Format 1
# 2. Strips out SysEx Midi messages (System Exclusive) that prevent it from working
# 3. Strips out Program_Change / Control_Change from channel 10 (Percussion) that prevent it from working
# 4. Renames Track in first TRACK_NAME Meta Event to something based on file name.
# 5. Doubles Tempo and expands measure for songs under 140 beats, so its easier to see timing.
# 6. Checks that MIDI file has drums in it.
# 7. Moves file into subdirectory called 'fixed/'
# 8. Optionally summarizes drums present in song.


begin
  require './midifile.rb'
  require './mididefs.rb'
rescue LoadError
  puts "Make sure midifile.rb and mididefs.rb are in same directory as MidiFixForSongBeats.rb"
  puts "They can be obtained from https://github.com/jledoux/MidiFixForSongBeats/"
  exit
end
require 'optparse'
require 'fileutils'

options = {}
options[:force] = false
options[:summary] = false
options[:multiplier] = nil
options[:output_dir] = 'fixed'
options[:use_filenames] = false
options[:no_trackname_change] = false

optparse = OptionParser.new do |opts|
    opts.banner = "Usage: ./MidiFixForSongBeats.rb [options] file1 file2 ..."
    opts.on('-h', '--help') do
        puts opts
        exit
    end
    opts.on('-f', '--force', "Convert even if no drum events.") do 
        options[:force] = true
    end
    opts.on('-d', '--debug', "Print debug messages.") do
        options[:debug] = true
    end
    opts.on('-m', '--multiplier [M]', "Force multiplier.  Use '-m 1' to disable multiplier.") do |arg|
        options[:multiplier] = arg.to_f
    end
    opts.on('-s', '--summary', 'Print summary of drums present.') do 
    options[:summary] = true
    end
    opts.on('-f', '--use-filenames', 'Use original filenames as track names.') do
        options[:use_filenames] = true
    end
    opts.on('-n', '--no_trackname_change', 'Use track names in midi without changing.  Overrides --use-filenames option.') do
        options[:no_trackname_change] = true
        options[:use_filenames] = false
    end
    opts.on('-o', '--output-dir OUTPUT_DIR', "Output directory.  Will be created if it doesn't exist.  Defaults to 'fixed'") do |arg|
    options[:output_dir] = arg
    end
end
optparse.parse!

if ARGV.empty?
  puts optparse
  exit(-1)
end

def debug_puts(options, msg)
    if options[:debug]
        puts msg
    end
end

debug_puts(options, "Options: #{options}")

def find_max_tempo_check_drums_seen(file_name, options)
    max_tempo = 0
    seen_drum = false
    drum_counts = Hash.new(0) 
    open(file_name) {|f|
        mr = Midifile.new f
        mr.each {|ev|
            if ev.meta == TEMPO  # Find Max Tempo in Song
                # Time between beats is specified in microseconds in three byte array
                time_per_beat_us = (ev.data[0] << 16) + (ev.data[1] << 8) + ev.data[2]
                new_tempo = 60*1000*1000/time_per_beat_us
                debug_puts(options, "Tempo: #{new_tempo}")
                if new_tempo > max_tempo
                    max_tempo = new_tempo
                end
            end
            if ev.code == NOTE_ON and ev.channel == 10 and ev.data2 > 0 
                # Find if drums are in song
                # drums on channel 10 and have non-zero velocity (ev.data2) 
                # (zero velocity is equivalent to note off)
                seen_drum = true
                drum_counts[ev.data1] += 1
            end
        }
    }
    if options[:summary] or options[:debug]
        puts "Drum Count Summary" 
        drum_counts.sort_by{|drum_label, counts| counts}.reverse!.each do |drum_label, counts|
            puts "#{Percussion_set[drum_label]} (#{drum_label}):".ljust(30) + counts.to_s.rjust(3)
        end
    end
    return max_tempo, seen_drum
end

def fix_midi_file(file_name, options)
    max_tempo, seen_drum = find_max_tempo_check_drums_seen(file_name, options)
    if not seen_drum and not options[:force]
        puts "No drum notes seen, not converting #{file_name}."
        puts "Specify '-f' to still convert even without drum notes."
        return 
    end
    if options[:multiplier]
        multiplier = options[:multiplier]
    else 
        multiplier = if max_tempo < 140 then 2 else 1 end
    end
    debug_puts(options, "Multiplier set to #{multiplier}")
    # if max_tempo is less than 140, expand measures by factor of 2.
    # Only do if max_tempo is less than 140 as 280 is max tempo allowed in Song Beats
    out = Midifile.new
    out.format = 0 # convert output file to format 0
    open(file_name) {|f|
        mr = Midifile.new f
        mr.each {|ev|
            ev.trkno = 0 if ev.trkno
            if ev.code == TRK_START
                out.add(ev)
                # Create new TRACK_NAME at start of file
                ev2 = MidiEvent.new(META, ev.trkno, ev.time, ev.delta)
                if not options[:no_trackname_change]
                    ev2.meta = TRACK_NAME
                    # This creates a track name based on file name
                    # First converts a CamelCase to add spaces between lowercase and uppercase letters 
                    # It also removes "../", converts underscores (_) to spaces, replaces double spaces with single spaces, trails leading trailing spaces, and strips '.mid' 
                    # E.g., a file named "ACDC - BackInBlack.mid" becomes "ACDC - Back In Black" in Track Name.
                    file_without_path = file_name.split('/')[-1]
                    if options[:use_filenames]
                        ev2.data = file_without_path
                    else
                        ev2.data = file_without_path.gsub(/([a-z])([A-Z])/, '\1 \2').gsub('_', ' ').gsub('.mid','').gsub('  ', ' ').gsub('  ', ' ').strip
                    end
                    debug_puts(options, "Setting TRACK_NAME to #{ev2.data}")
                    ev2.length = ev2.data.length
                    out.add(ev2)
                end
            elsif ev.meta == TEMPO
                # if multiplier != 1 this adjusts the TEMPO correspondingly.
                half_time_us = ((ev.data[0] << 16) + (ev.data[1] << 8) + ev.data[2]) / multiplier
                a = half_time_us / (1 << 16)
                b = (half_time_us - (a << 16)) / (1 << 8)
                c = half_time_us - (a << 16) - (b << 8)
                ev.data = MString.new ([a, b, c].pack("CCC"))
                out.add(ev)
            elsif ev.code == HDR
              #this adds more notes per division if multiplier != 1
                out.division = ev.division / multiplier
            elsif ev.channel == 10 and [CONTROL_CHANGE, PROGRAM_CHANGE].include? ev.code 
                debug_puts(options, "skip #{ev}")
                if ev.code == PROGRAM_CHANGE
                    debug_puts(options, "#{EvType[ev.code]}: '#{Program_set[ev.data1]}' (#{ev.data1 + 1}) #{ev.running ? '[running]' : ''}")
                else
                    debug_puts(options, "#{EvType[ev.code]}: '#{Controller_set[ev.data1]}' (#{ev.data1}) value: #{ev.data2} #{ev.running ? '[running]' : ''}")
                end
            elsif [SYSEX, SYSEX_CONT].include? ev.code
                debug_puts(options, "skip SYSEX #{ev}")
            else
                out.add(ev)
            end
        } # end event loop
    } # close read midifile
    directory_name = options[:output_dir]
    Dir.mkdir(directory_name) unless File.exists?(directory_name)
    open(directory_name + '/' + file_name,"w") {|fw|
        out.to_stream(fw) if out.vet()
    }
    debug_puts(options, "Wrote file: #{directory_name}/#{file_name}")
end


for file_name in ARGV
    debug_puts(options, "Processing #{file_name}")
    begin
      fix_midi_file(file_name, options)
    rescue
      puts "Error processing '#{file_name}'; likely invalid/corrupt midi file."
    end
end
