require 'sshkit/formatters/pretty'
require_relative 'jenkins_output'

class JenkinsSSHKitFormatter < SSHKit::Formatter::Pretty

  def initialize(native)
    super(JenkinsOutput.new(native))
  end
end