require 'sshkit/formatters/abstract'
require_relative 'jenkins_output'

class JenkinsSSHKitFormatter < SSHKit::Formatter::Pretty

  def initialize(native = nil)
    super(JenkinsOutput.new(native))
  end
end