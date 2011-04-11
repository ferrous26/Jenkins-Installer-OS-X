#!/usr/bin/env macruby

require 'fileutils'
include FileUtils

JENKINS_DOWNLOAD_URL = 'http://mirrors.jenkins-ci.org/war/latest/jenkins.war'
JENKINS_INSTALL_DIR  = '/Library/Application Support/Jenkins'
JENKINS_WAR_FILE     = File.join( JENKINS_INSTALL_DIR, 'jenkins.war' )
JENKINS_HOME_DIR     = File.join( JENKINS_INSTALL_DIR, 'working_dir' )
JENKINS_LOG_DIR      = '/Library/Logs/Jenkins'

def write_file filename, &block
  File.open( filename, 'w', &block )
end


### Setup directories

mkdir JENKINS_INSTALL_DIR
mkdir JENKINS_HOME_DIR
mkdir JENKINS_LOG_DIR


### Download and install the .war file

jenkins_url = NSURL.alloc.initWithString JENKINS_DOWNLOAD_URL
jenkins_war = NSMutableData.dataWithContentsOfURL jenkins_url

raise 'Failed to download Jenkins' if jenkins_war.nil?

write_file(JENKINS_WAR_FILE) { |file| file.write String.new(jenkins_war) }


### Launchd setup

LAUNCHD_LABEL     = 'org.jenkins-ci.jenkins'
LAUNCHD_DIRECTORY = '/Library/LaunchDaemons'
LAUNCHD_FILE      = "#{LAUNCHD_LABEL}.plist"
LAUNCHD_SCRIPT    = {
  'Label'                => LAUNCHD_LABEL,
  'KeepAlive'            => true, # or maybe RunAtLoad would be better?
  'EnvironmentVariables' => { 'JENKINS_HOME' => JENKINS_HOME_DIR },
  'StandardOutPath'      => File.join(JENKINS_LOG_DIR, 'jenkins.log'),
  'StandardErrorPath'    => File.join(JENKINS_LOG_DIR, 'jenkins-error.log'),
  'Program'              => '/usr/bin/java',
  'ProgramArguments'     => [ '-jar', JENKINS_WAR_FILE, '--httpPort=9001' ]
  # @todo Maybe setup Bonjour using the Socket key
}

# this step requires root permissions
write_file File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE) do |file|
  file.write LAUNCHD_SCRIPT.to_plist
end
