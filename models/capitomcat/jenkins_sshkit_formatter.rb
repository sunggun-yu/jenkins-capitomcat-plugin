require 'sshkit/formatters/abstract'
require 'sshkit/formatters/pretty'
require_relative 'jenkins_output'

module Capitomcat
  class JenkinsSSHKitFormatter < SSHKit::Formatter::Pretty

    def initialize(native)
      super(JenkinsOutput.new(native))
    end
  end
end
