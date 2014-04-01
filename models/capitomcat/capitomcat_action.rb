require 'rake'
require 'capistrano/all'
require 'capistrano/setup'
require 'sshkit'
require 'fileutils'
require_relative 'jenkins_sshkit_formatter'
require_relative 'jenkins_output'
require_relative 'capitomcat_utils'
require_relative 'application'

module Capitomcat

  class CapitomcatAction

    def initialize(task, build, listener)
      @task = task
      @build = build
      @listener = listener
    end

    def configure
      Capistrano::Configuration.reset!
      config_global_ssh(@task.pty.to_bool)
      config_out_formatter() if @task.log_verbose.to_bool
      @utils = CapitomcatUtils.new(@task, @build.send(:native).getEnvironment(@listener))
    end

    def execute
      configure()
      set_variables()
      do_deploy()
    end

    private

    def set_variables

      set :stage, :dev

      set :format, :pretty
      set :log_level, :debug
      set :use_sudo, true

      # Server definition section
      setup_servers()

      # Remote Tomcat server setting section
      set :tomcat_user, @task.tomcat_user
      set :tomcat_user_group, @task.tomcat_user_group
      set :tomcat_port, @task.tomcat_port
      set :tomcat_cmd, @task.tomcat_cmd
      set :use_tomcat_user_cmd, @task.use_tomcat_user_cmd.to_bool

      set :tomcat_war_file, @utils.get_tomcat_war_file
      set :tomcat_context_path, @utils.get_tomcat_context_path
      set :tomcat_context_file, @utils.get_tomcat_context_file
      set :tomcat_work_dir, @utils.get_tomcat_work_dir

      # Deploy setting section
      set :local_war_file, @utils.get_local_war_file
      set :context_template_file, File.expand_path('../templates/context.xml.erb', __FILE__).to_s
      set :use_context_update, @utils.is_use_context_update
      set :use_parallel, @task.use_parallel.to_bool
      set :listener, @listener

      if @task.log_verbose.to_bool
        @listener.debug('---------------------------------------------------------------------------')
        @listener.debug('Capitomcat Configs')
        @listener.debug('---------------------------------------------------------------------------')
        @listener.debug("remote_hosts          => #{@task.remote_hosts.to_s}")
        @listener.debug("user_account          => #{@task.user_account}")
        @listener.debug("auth_method           => #{@task.auth_method}")
        @listener.debug("pty                   => #{@task.pty}")
        @listener.debug("local_war_file        => #{fetch(:local_war_file)}")
        @listener.debug("tomcat_user           => #{fetch(:tomcat_user)}")
        @listener.debug("tomcat_user_group     => #{fetch(:tomcat_user_group)}")
        @listener.debug("tomcat_port           => #{fetch(:tomcat_port)}")
        @listener.debug("tomcat_cmd            => #{fetch(:tomcat_cmd)}")
        @listener.debug("use_tomcat_user_cmd   => #{fetch(:use_tomcat_user_cmd)}")
        @listener.debug("use_context_update    => #{fetch(:use_context_update)}")
        @listener.debug("tomcat_context_path   => #{fetch(:tomcat_context_path)}")
        @listener.debug("tomcat_context_file   => #{fetch(:tomcat_context_file)}")
        @listener.debug("tomcat_work_dir       => #{fetch(:tomcat_work_dir)}")
        @listener.debug("context_template_file => #{fetch(:context_template_file)}")
        @listener.debug("tomcat_war_file       => #{fetch(:tomcat_war_file)}")
        @listener.debug("use_parallel          => #{fetch(:use_parallel)}")
      end
    end

    def do_deploy

      capitomcat_task_name = 'capitomcat_jenkins:deploy'

      require 'capistrano/deploy'
      require 'capitomcat'

      is_task_exist = false
      # Clearing Rake tasks
      Rake.application.clear
      # check capitomcat task existing : just in case
      Rake.application.tasks.each do |t|
        if t.name == capitomcat_task_name
          t.reenable
          is_task_exist = true
          puts "[#{capitomcat_task_name}] re-enabled"
        end
      end

      capistrano = Capitomcat::Application.new
      # adding import for capitomcat recipe
      if is_task_exist == false
        cap_file = File.expand_path('../caps/capitomcat.cap', __FILE__).to_s
        capistrano.add_import(cap_file)
        capistrano.load_imports
        puts "[#{capitomcat_task_name}] added"
      end
      capistrano.invoke(capitomcat_task_name)
    end

    def setup_servers
      @task.remote_hosts.gsub(' ', '').split(',').each do |host|
        prop = Hash.new
        ssh = Hash.new

        prop[:user] = @task.user_account
        prop[:roles] = %w{app}
        prop[:ssh_options] = ssh

        ssh[:user] = @task.user_account
        ssh[:keys] = [@task.ssh_key_file] if @task.auth_method == 'publickey' && @task.ssh_key_file.length > 0
        ssh[:forward_agent] = false

        if @task.auth_method == 'password'
          ssh[:auth_methods] = %w(password)
          ssh[:password] = @task.user_pw
        else
          ssh[:auth_methods] = %w(publickey)
        end
        server host, prop
      end
    end

    def config_out_formatter
      SSHKit.config.output = JenkinsSSHKitFormatter.new(@listener.native)
    end

    def config_global_ssh(pty)
      SSHKit::Backend::Netssh.pool.idle_timeout = 0
      SSHKit::Backend::Netssh.configure do |ssh|
        ssh.connection_timeout = 30
        ssh.pty = pty
      end
    end
  end
end

