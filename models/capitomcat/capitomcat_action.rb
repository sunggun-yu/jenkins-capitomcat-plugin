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
      @env_vars = @build.send(:native).getEnvironment(@listener)
      @env_map = EnvUtils.new(task, @env_vars).get_substituted_env_map
      @utils = CapitomcatUtils.new(@env_map)
    end

    def configure
      Capistrano::Configuration.reset!
      config_global_ssh(@env_map['pty'].to_bool)
      config_out_formatter() if @env_map['log_verbose'].to_bool
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
      set :tomcat_user, @env_map['tomcat_user']
      set :tomcat_user_group, @env_map['tomcat_user_group']
      set :tomcat_port, @env_map['tomcat_port']
      set :tomcat_cmd, @env_map['tomcat_cmd']
      set :use_tomcat_user_cmd, @env_map['use_tomcat_user_cmd'].to_bool

      set :tomcat_war_file, @utils.get_tomcat_war_file
      set :tomcat_context_path, @utils.get_tomcat_context_path
      set :tomcat_context_file, @utils.get_tomcat_context_file
      set :tomcat_work_dir, @utils.get_tomcat_work_dir
      set :tomcat_cmd_wait_start, @env_map['tomcat_cmd_wait_start']
      set :tomcat_cmd_wait_stop, @env_map['tomcat_cmd_wait_stop']
      # reverted true/false for use_background_tomcat_cmd to make USE-NO as default
      set :use_background_tomcat_cmd, @env_map['use_background_tomcat_cmd'].to_s.length > 0 ? @env_map['use_background_tomcat_cmd'].to_bool : false

      # Deploy setting section
      set :local_war_file, @env_map['local_war_file']
      set :context_template_file, File.expand_path('../templates/context.xml.erb', __FILE__).to_s
      set :use_context_update, @utils.is_use_context_update
      set :use_parallel, @env_map['use_parallel'].to_bool
      set :listener, @listener

      if @env_map['log_verbose'].to_bool
        @listener.debug('---------------------------------------------------------------------------')
        @listener.debug('Capitomcat Configs')
        @listener.debug('---------------------------------------------------------------------------')
        @listener.debug("remote_hosts          => #{@env_map['remote_hosts']}")
        @listener.debug("user_account          => #{@env_map['user_account']}")
        @listener.debug("auth_method           => #{@env_map['auth_method']}")
        @listener.debug("pty                   => #{@env_map['pty']}")
        @listener.debug("ssh_port              => #{@env_map['ssh_port']}")
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
        @listener.debug("env_vars              => #{@env_vars}")
        @listener.debug("env_map               => #{@env_map}")
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
      @env_map['remote_hosts'].gsub(' ', '').split(',').each do |host|
        prop = Hash.new
        ssh = Hash.new

        prop[:user] = @env_map['user_account']
        prop[:roles] = %w{app}
        prop[:ssh_options] = ssh

        ssh[:user] = @env_map['user_account']
        ssh[:keys] = [@env_map['ssh_key_file']] if @env_map['auth_method'] == 'publickey' && @env_map['ssh_key_file'].length > 0
        ssh[:forward_agent] = false

        ssh_port = @env_map['ssh_port'].to_i
        if ssh_port > 0 && ssh_port != 22
          ssh[:port] = ssh_port
        end
        if @env_map['auth_method'] == 'password'
          ssh[:auth_methods] = %w(password)
          ssh[:password] = @env_map['user_pw']
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

