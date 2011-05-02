#!/usr/bin/env macruby
STATUS_NOT_RUNNING = 0
STATUS_RUNNING = 1
LAUNCHD_LABEL     = 'org.jenkins-ci.jenkins'
LAUNCHD_DIRECTORY = '/Library/LaunchDaemons'
LAUNCHD_FILE      = "#{LAUNCHD_LABEL}.plist"
JENKINS_INSTALL_DIR  = '/Library/Application Support/Jenkins'

framework 'Foundation'

require "strscan"  
require 'fileutils'
   
include FileUtils     

def _status()
list = `sudo launchctl list | grep "#{LAUNCHD_LABEL}"`  
  if list.length < 1
    return STATUS_NOT_RUNNING
  end  
  scanner = StringScanner.new(list)
  process_id = scanner.scan(/\w+/)
  if process_id != '-'
    return STATUS_RUNNING 
  end                        
  return STATUS_NOT_RUNNING
end       
         


unless ENV['USER'] == 'root'
  NSLog('You need to run this script as root.')
  exit
end

if ARGV.length != 1 || (ARGV[0] != 'start' && ARGV[0] != 'stop' && ARGV[0] != 'status') 
  print "Please use jenkins_ctl.rb {start | stop | status}\n"
  exit
end   



if ARGV[0] == 'status'
  if _status() == STATUS_NOT_RUNNING
   NSLog('Jenkins is not running')
  else
    NSLog('Jenkins is running')
  end
  
end
if ARGV[0] == 'stop'
  if _status() == STATUS_NOT_RUNNING
     NSLog('Jenkins is not running')  
     exit
  end
  `sudo launchctl unload  #{File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE)}`
  remove([File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE)])
end    

if ARGV[0] == 'start'
  if _status() == STATUS_RUNNING
     NSLog('Jenkins is already running')  
     exit
  end
  if !File::exists?( File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE) )
     ln_s(File.join(JENKINS_INSTALL_DIR, LAUNCHD_FILE),File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE)) 
  end
  `sudo launchctl load  #{File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE)}`
  
  
end    