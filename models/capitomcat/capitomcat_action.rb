require 'rake'
require 'capistrano/all'
require 'capistrano/setup'
require 'sshkit'
require 'fileutils'
require_relative 'jenkins_sshkit_formatter'
require_relative 'jenkins_output'
require_relative 'capitomcat_utils'

module Capitomcat

  class CapitomcatAction

    def initialize(task, build, listener)
      @task = task
      @build = build
      @listener = listener
    end

    def configure
      config_global_ssh()
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
      set :log_level, :info
      set :pty, true
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

      puts "remote_hosts : #{@task.remote_hosts}"
      puts "user_account : #{@task.user_account}"
      puts "tomcat_user : #{fetch(:tomcat_user)}"
      puts "tomcat_user_group : #{fetch(:tomcat_user_group)}"
      puts "tomcat_port : #{fetch(:tomcat_port)}"
      puts "tomcat_cmd : #{fetch(:tomcat_cmd)}"
      puts "use_tomcat_user_cmd : #{fetch(:use_tomcat_user_cmd)}"
      puts "tomcat_war_file : #{fetch(:tomcat_war_file)}"
      puts "tomcat_context_path : #{fetch(:tomcat_context_path)}"
      puts "tomcat_context_file : #{fetch(:tomcat_context_file)}"
      puts "tomcat_work_dir : #{fetch(:tomcat_work_dir)}"
      puts "local_war_file : #{fetch(:local_war_file)}"
      puts "context_template_file : #{fetch(:context_template_file)}"
      puts "use_context_update : #{fetch(:use_context_update)}"
      puts "use_parallel : #{fetch(:use_parallel)}"
    end

    def do_deploy

      capitomcat_task_name = 'capitomcat_jenkins:deploy'

      require 'capistrano/deploy'
      require 'capitomcat'

      is_task_exist = false

      Rake.application.clear

      # check capitomcat task existing
      Rake.application.tasks.each do |t|
        if t.name == capitomcat_task_name
          t.reenable
          is_task_exist = true
          puts "[#{capitomcat_task_name}] re-enabled"
        end
      end
      Capistrano::Application
      capistrano = Capistrano::Application.new
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
      @task.remote_hosts.split(',').each do |host|
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
        puts prop.to_s
        server host, prop
      end
    end

    def config_out_formatter
      SSHKit.config.output = JenkinsSSHKitFormatter.new(@listener.native)
    end

    def config_global_ssh
      SSHKit::Backend::Netssh.pool.idle_timeout = 0
    end
  end
end


