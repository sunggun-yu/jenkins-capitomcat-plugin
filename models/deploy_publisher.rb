require 'fileutils'
require 'erb'
require 'zip'

class DeployPublisher < Jenkins::Tasks::Publisher

  attr_accessor :remote_hosts,
                :remote_tomcat_home,
                :remote_tomcat_hostname,
                :remote_tomcat_cmd,
                :tomcat_user,
                :tomcat_user_group,
                :tomcat_port
  attr_accessor :local_war_file,
                :is_parallel,
                :remote_doc_base
  attr_accessor :update_context, :context_name

  display_name 'Deploy via Capitomcat'
  # Invoked with the form parameters when this extension point
  # is created from a configuration screen.
  def initialize(attrs = {})
    @remote_hosts = attrs['remote_hosts']
    @remote_tomcat_home = attrs['remote_tomcat_home']
    @remote_tomcat_hostname = attrs['remote_tomcat_hostname']
    @remote_tomcat_cmd = attrs['remote_tomcat_cmd']
    @tomcat_user = attrs['tomcat_user']
    @tomcat_user_group = attrs['tomcat_user_group']
    @tomcat_port = attrs['tomcat_port']

    @local_war_file = attrs['local_war_file']
    @is_parallel = attrs['is_parallel']
    @remote_docBase = attrs['remote_doc_base']
    @update_context = attrs['update_context']
    @context_name = attrs['context_name']
  end

  ##
  # Runs before the build begins
  #
  # @param [Jenkins::Model::Build] build the build which will begin
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def prebuild(build, listener)
    workspace = build.send(:native).workspace.to_s

    # Copy recipe into workspace
    install_recipe(workspace)

    if is_parallel
      puts "#{is_parallel}"
    end

    puts "#{update_context}"
    puts "#{context_name}"

    # Generate and save config template
    #save_config_template(workspace)
  end

  ##
  # Runs the step over the given build and reports the progress to the listener.
  #
  # @param [Jenkins::Model::Build] build on which to run this step
  # @param [Jenkins::Launcher] launcher the launcher that can run code on the node running this build
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def perform(build, launcher, listener)
    # actually perform the build step

    # Execute the Capistrano script
    #launch_cap(launcher, listener)
  end

  # Install basic recipe into workspace
  def install_recipe(workspace)
    # Copy recipe into workspace
    #recipe_dir = File.expand_path('../template/recipe/single', __FILE__)
    #FileUtils.cp_r recipe_dir, Pathname.new(workspace)
    recipe_zip = File.expand_path('../template/recipes/single.zip', __FILE__)
    unzip_file(recipe_zip, workspace)
  end

  # Generate config template
  def generate_config_template
    bind_erb_variables()
    template_file = File.read(File.expand_path('../template/config.rb.erb', __FILE__))
    return ERB.new(template_file).result(binding)
  end

  # Save config template file into workspace
  def save_config_template (workspace)
    config_dir = Pathname.new(workspace + '/single/config')
    file = config_dir.join('config.rb')
    File.open(file, 'w+') do |f|
      f.write(generate_config_template)
    end
  end

  # Launch CAP command
  def launch_cap(launcher, listener)
    launcher.execute('bash', '-c', 'cd #{workspace}/single; cap single deploy:startRelease', {:out => listener})
  end

  # Unzip file
  def unzip_file(file, destination)
    if File.exist?(destination) then
      FileUtils.rm_rf destination
    end
    Zip::File.open(file) { |zip_file|
      zip_file.each { |f|
        f_path=File.join(destination, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path)
      }
    }
  end

  def bind_erb_variables
    set_remote_context_file()
    set_remote_tomcat_work_dir()
  end

  def set_remote_context_file

  end

  def set_remote_tomcat_work_dir

  end
end