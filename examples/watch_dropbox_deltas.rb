# An example use of #delta_latest_cursor / #longpoll_delta / #delta calls.
# "Tails" the delta feed (optionally, for some path_prefix), showing each
# change entry in near-real-time using the longpoll API.  Each API call, and
# each result, is shown.  Interrupt (e.g. with CTRL-C) to finish.
#
# You'll need to have created an app
# (https://www.dropbox.com/developers/apps/create), and generated an access
# token.
#
# Example usage:
#
# DROPBOX_RUBY_SDK_ACCESS_TOKEN=<oauth2-access-token> ruby watch_dropbox_deltas.rb [<path-prefix>]

require File.expand_path('../../lib/dropbox_sdk', __FILE__)

def get_dropbox_client
  ENV["DROPBOX_RUBY_SDK_ACCESS_TOKEN"] or raise "You need to set the DROPBOX_RUBY_SDK_ACCESS_TOKEN env var to run this script"
  dbx = DropboxClient.new(ENV["DROPBOX_RUBY_SDK_ACCESS_TOKEN"])
end

$stdout.sync = true

dbx = get_dropbox_client

path_prefix = ARGV.first

puts "> latest_cursor #{path_prefix.inspect}"
lc_r = dbx.delta_latest_cursor(path_prefix)
puts "< #{lc_r.inspect}"
cursor = lc_r["cursor"]

while true
  puts "> longpoll_delta #{cursor.inspect}"
  lpd_r = dbx.longpoll_delta(cursor)
  puts "< #{lpd_r.inspect}"

  if lpd_r["changes"]

    puts "> delta #{cursor.inspect}, #{path_prefix.inspect}"
    d_r = dbx.delta(cursor, path_prefix)
    puts "< #{d_r.inspect}"

    d_r["entries"].each do |entry|
      puts " >> #{entry.inspect}"
    end
    if d_r["reset"]
      puts "ALERT!  Local reset requested!"
    end
    cursor = d_r["cursor"]
    next if d_r["has_more"]

  end

  if lpd_r["backoff"]
    puts "sleeping for #{lpd_r["backoff"]} sec"
    sleep lpd_r["backoff"]
  end
end
