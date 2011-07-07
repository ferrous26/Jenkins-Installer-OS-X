#!/usr/bin/env ruby

STATUS_NOT_RUNNING  = 0
STATUS_RUNNING      = 1
LAUNCHD_LABEL       = 'org.jenkins-ci.jenkins'
LAUNCHD_DIRECTORY   = '/Library/LaunchDaemons'
LAUNCHD_FILE        = "#{LAUNCHD_LABEL}.plist"
LAUNCHD_PATH        = File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE)
JENKINS_INSTALL_DIR = '/Library/Application Support/Jenkins'

require   'strscan'
require   'fileutils'

include FileUtils


unless ENV['USER'] == 'root'
  $stderr.puts 'You need to run this script as root.'
  exit
end


def status
  list = `sudo launchctl list | grep "#{LAUNCHD_LABEL}"`
  return STATUS_NOT_RUNNING if list.length < 1
  scanner = StringScanner.new(list)
  process_id = scanner.scan(/\w+/)
  (process_id != '-') ? STATUS_RUNNING : STATUS_NOT_RUNNING
end

case ARGV[0]
when 'status'
  msg = (status == STATUS_NOT_RUNNING) ? 'not running' : 'running'
  $stderr.puts 'Jenkins is ' + msg

when 'stop'
  unless status == STATUS_NOT_RUNNING
    `sudo launchctl unload #{LAUNCHD_PATH}`
    rm LAUNCHD_PATH
  else
    $stderr.puts 'Jenkins is not running'
    exit
  end

when 'start'
  if status == STATUS_RUNNING
    $stderr.puts 'Jenkins is already running'
    exit
  end
  unless File.exists? LAUNCHD_PATH
    ln_s File.join(JENKINS_INSTALL_DIR, LAUNCHD_FILE), LAUNCHD_PATH
  end
  `sudo launchctl load #{LAUNCHD_PATH}`

else
  print "Please use jenkins_ctl.rb {start | stop | status}\n"

end
