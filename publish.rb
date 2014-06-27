#
# nice pearl 'borrowed' from:
# http://www.mail-archive.com/sup-devel@rubyforge.org/msg01047.html
#
# this publish hook (Press P in thread view)
# converts the message (including inline images!) to html and opens
# google-chrome with the result.
#
# Provides for close-to-instant pretty output in case you need pictures.
# - Uses mhonarc <www.mhonarc.org> for conversion.
# - Defaults to google-chrome for rendering, can be easily changed in $browser.

# The exec to invoke when opening a converted html message.
$browser ||= 'google-chrome'

# work directory for the hook (stores .msg input and all outputs of the conversion)
# when the hook is invoked it attempts to clean up files older than a day.
# see: housekeeping_for_work_dir
$work_dir ||= '/tmp/sup-publish-hook/'


# housekeeping routine for $work_dir
def housekeeping_for_work_dir
    amount_of_files = 0
    amount_of_files = `find #{$work_dir}* -ctime 1 -type f | wc -l`.to_i if is_manageable_work_dir?
    if amount_of_files > 0
        log "Cleaning up #{amount_of_files} file(s) older then a day"
        system "find #{$work_dir}* -ctime 1 -type f | xargs rm > /dev/null 2>&1"
        log "Done cleaning up #{amount_of_files} file(s)"
    end
end

# if $work_dir is somewhere in /tmp, does not contain dir ups (/../) but only [A-Za-z\/-_].
# used to auto-create and semi-auto-clean (manage) $work_dir.
def is_manageable_work_dir?
    $work_dir =~ /^\/tmp\/[A-Za-z\/\-_]+\/$/
end

# Convert a .msg file with the mime message content to html
def convert message_filename
    say "Converting #{message_filename}"
    log "Converting #{message_filename}"
    raise "mhonarc not found on PATH" unless system "which mhonarc > /dev/null 2>1"
    clean_filename = clean_filename(message_filename)
    system "cd #{$work_dir} && mhonarc -single #{clean_filename} 2> /dev/null > #{clean_filename}.html"
    log "Done #{message_filename}"
end

# converts an arbitratry string filename in a short numerical hash.
# feels nicer to inject in system calls then message subject based
# name.
def clean_filename filename
    filename.hash.abs()
end

# opens an html representation of the mail message in the browser
def open_url message_filename
    log "Opening #{message_filename}.html"
    say "Opening #{message_filename}.html"
    raise "#{$browser} not found on PATH" unless system "which #{$browser} > /dev/null 2>1"
    system "cd #{$work_dir} && #{$browser} #{$work_dir}/#{clean_filename(message_filename)}.html > /dev/null 2>&1 &"
    system "wmctrl -a Chrome"
end

def sanitize_filename filename
    filename.gsub(/[^a-zA-Z0-9åäöÅÄÖ_.-]/, '_').gsub(/_+/, '_')
end

def work_dir_exists?
    File.exists? $work_dir
end

def save_to_file_succeeds filename
    if not work_dir_exists? and not is_manageable_work_dir?
        log "Working directory does not exist and will not be auto-created: #{$work_dir}"
        BufferManager.flash "Please create the work directory: #{$work_dir}!"
        false
    else
        if not work_dir_exists?
            log "Creating working directory: #{$work_dir}"
            system "mkdir -p #{$work_dir}"
        end
        begin
            File.open("#{$work_dir}#{filename}", "w") { |file| yield file }
            true
        rescue SystemCallError, IOError => e
            m = "Error writing file: #{e.message}"
            info m
            BufferManager.flash m
            false
        end
    end
end

# main entry point for module.
# open the 'hook'ed chunk in a $browser.
def open_in_browser chunk
    mime_content = ''
    message_filename = nil

    case chunk
    when Redwood::Message
        message_filename = sanitize_filename(chunk.subj[0..30]) + '.msg'
        log "Processing message #{message_filename}"
        mime_content += chunk.raw_message
        log "Done message #{message_filename}"
    when Redwood::Chunk::Attachment
        attachment_filename = $work_dir + chunk.filename
        log "Processing attachment #{attachment_filename} for #{message_filename}"
        mime_content = chunk.raw_content
        log "Done attachment #{attachment_filename} for #{message_filename}"
    else
        BufferManager.flash 'Dunno how to publish ' + chunk.class.name
        return false
    end

    if save_to_file_succeeds("#{clean_filename(message_filename)}") { |file| file.print mime_content }
        convert(message_filename)
        open_url(message_filename)
        housekeeping_for_work_dir()
        return true
    end

    return false
end

open_in_browser(chunk)
