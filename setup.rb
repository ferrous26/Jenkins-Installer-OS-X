#!/usr/bin/env macruby

framework 'Foundation'

require 'fileutils'
include FileUtils


unless ENV['USER'] == 'root'
  NSLog('You need to run this script as root.')
  exit
end


JENKINS_DOWNLOAD_URL = 'http://mirrors.jenkins-ci.org/war/latest/jenkins.war'
JENKINS_INSTALL_DIR  = '/Library/Application Support/Jenkins'
JENKINS_WAR_FILE     = File.join( JENKINS_INSTALL_DIR, 'jenkins.war' )
JENKINS_HOME_DIR     = File.join( JENKINS_INSTALL_DIR, 'working_dir' )
JENKINS_LOG_DIR      = '/Library/Logs/Jenkins'

def write_file filename, &block
  File.open( filename, 'w', &block )
end


### Setup directories
NSLog('Creating data and logging directories')
mkdir_p [JENKINS_INSTALL_DIR, JENKINS_HOME_DIR, JENKINS_LOG_DIR]


### Download and install the .war file
NSLog('Downloading the latest release of Jenkins')
jenkins_url = NSURL.alloc.initWithString JENKINS_DOWNLOAD_URL
jenkins_war = NSMutableData.dataWithContentsOfURL jenkins_url
raise 'Failed to download Jenkins' if jenkins_war.nil?

NSLog('Installing Jenkins')
write_file(JENKINS_WAR_FILE) { |file| file.write String.new(jenkins_war) }


### Launchd setup
NSLog('Creating launchd plist')
LAUNCHD_LABEL     = 'org.jenkins-ci.jenkins'
LAUNCHD_DIRECTORY = '/Library/LaunchDaemons'
LAUNCHD_FILE      = "#{LAUNCHD_LABEL}.plist"
LAUNCHD_SCRIPT    = {
  'Label'                => LAUNCHD_LABEL,
  'RunAtLoad'            => true,
  'EnvironmentVariables' => { 'JENKINS_HOME' => JENKINS_HOME_DIR },
  'StandardOutPath'      => File.join(JENKINS_LOG_DIR, 'jenkins.log'),
  'StandardErrorPath'    => File.join(JENKINS_LOG_DIR, 'jenkins-error.log'),
  'ProgramArguments'     => [ '/usr/bin/java', '-jar', JENKINS_WAR_FILE ]
  # @todo Maybe setup Bonjour using the Socket key
}

NSLog('Installing launchd plist')
write_file File.join(LAUNCHD_DIRECTORY, LAUNCHD_FILE) do |file|
  file.write LAUNCHD_SCRIPT.to_plist
end
NSLog('Jenkins install complete.')
