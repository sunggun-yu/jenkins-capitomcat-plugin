require 'fileutils'
require_relative 'capitomcat_builder'
require 'jenkins/model/listener'
require 'jenkins/launcher'
require 'jenkins/model/build'
require 'jenkins/model/environment'

class DeployPublisher < Jenkins::Tasks::Publisher

  attr_accessor :remote_hosts,
                :tomcat_user,
                :tomcat_user_group,
                :tomcat_port,
                :tomcat_cmd,
                :use_tomcat_user_cmd,
                :tomcat_war_file,
                :tomcat_context_path,
                :tomcat_context_file,
                :tomcat_work_dir,
                :local_war_file,
                :use_parallel,
                :use_context_update

  display_name 'Deploy via Capitomcat'

  def initialize(attrs = {})
    attrs.each { |k, v| instance_variable_set "@#{k}", v }
  end

  def perform(build, launcher, listener)
    begin
      listener.info 'Starting Capitomcat Tomcat deploy'
      capi_builder  = CapitomcatBuilder.new self, build, listener
      capi_builder.do_deploy
      listener.info 'Capitomcat deploy has finished successfully'
    rescue => e
      listener.error ['Capitomcat deploy has failed', e.message, e.backtrace] * "\n"
      build.abort
    end
  end
end