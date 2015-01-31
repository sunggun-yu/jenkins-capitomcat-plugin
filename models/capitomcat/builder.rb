require 'jenkins/model'
require 'jenkins/model/describable'
require 'jenkins/tasks/build_step'
require 'json'
require_relative 'capitomcat_action'
require_relative 'builder_descriptor'

module Capitomcat
  class Builder
    include Jenkins::Model
    include Jenkins::Model::Describable
    include Jenkins::Tasks::BuildStep

    describe_as Java.hudson.tasks.Builder, :with => Capitomcat::BuilderDescriptor

    attr_accessor :local_war_file,
                  :remote_hosts,
                  :use_parallel,
                  :log_verbose,
                  :use_ssh_key_file,
                  :ssh_key_file,
                  :use_context_update,
                  :tomcat_context_name,
                  :tomcat_context_path,
                  :tomcat_doc_base,
                  :tomcat_home,
                  :tomcat_user,
                  :tomcat_user_group,
                  :tomcat_cmd,
                  :use_tomcat_user_cmd,
                  :tomcat_engine,
                  :tomcat_vhost,
                  :tomcat_app_base,
                  :tomcat_port,
                  :user_account,
                  :auth_method,
                  :user_pw,
                  :pty,
                  :ssh_port,
                  :tomcat_cmd_wait_start,
                  :tomcat_cmd_wait_stop,
                  :use_background_tomcat_cmd

    display_name 'Deploy WAR file to Tomcat via Capitomcat'

    # Invoked with the form parameters when this extension point
    # is created from a configuration screen.
    def initialize(attrs = {})
      attrs.each { |k, v| instance_variable_set "@#{k}", v }
    end

    ##
    # Runs before the build begins
    #
    # @param [Jenkins::Model::Build] build the build which will begin
    # @param [Jenkins::Model::Listener] listener the listener for this build.
    def prebuild(build, listener)

    end

    ##
    # Runs the step over the given build and reports the progress to the listener.
    #
    # @param [Jenkins::Model::Build] build on which to run this step
    # @param [Jenkins::Launcher] launcher the launcher that can run code on the node running this build
    # @param [Jenkins::Model::Listener] listener the listener for this build.
    def perform(build, launcher, listener)
      black_status = %w(ABORTED FAILURE NOT_BUILT UNSTABLE)
      if black_status.include?build.native.getResult().to_s
        listener.error('Capitomcat deployment has aborted by the previous build was not succeed.')
      else
        invoke(build, launcher, listener)
      end
    end

    def invoke(build, launcher, listener)
      begin
        listener.info 'Starting Capitomcat Tomcat deploy'
        capi_builder = CapitomcatAction.new self, build, listener
        capi_builder.execute
        build.native.setResult(Java.hudson.model.Result::SUCCESS)
        listener.info 'Capitomcat deploy has finished successfully'
      rescue => e
        listener.error [e.message, e.backtrace] * "\n"
        raise 'Capitomcat deploy has failed'
      end
    end
  end
end