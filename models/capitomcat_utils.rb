class CapitomcatUtils

  def initialize(task, env_vars)
    @task = task
    @env_vars = env_vars
  end

  def get_tomcat_work_dir
    return get_base_dir('work')
  end

  def get_tomcat_war_file
    if @task.use_context_update.to_bool
      return return substitute_env_vars(@task.tomcat_doc_base)
    else
      return File.join(@task.tomcat_home, @task.tomcat_vhost, @task.tomcat_app_base, get_tomcat_context_name() + '.war').to_s
    end
  end

  def get_tomcat_context_file
    return "#{get_base_dir('conf')}.xml"
  end

  def get_local_war_file
    return substitute_env_vars(@task.local_war_file)
  end

  def get_tomcat_context_name
    if @task.use_context_update.to_bool
      return @task.tomcat_context_name
    else
      local_war_file = get_local_war_file()
      ext_name = File.extname(local_war_file)
      return File.basename(local_war_file, ext_name).to_s
    end
  end

  private
  def get_base_dir(base)
    return File.join(@task.tomcat_home, base, @task.tomcat_engine, @task.tomcat_vhost, get_tomcat_context_name()).to_s
  end

  def substitute_env_vars(txt)
    _txt = txt
    @env_vars.each do |env_key, env_value|
      _txt = _txt.gsub("$#{env_key}", env_value)
    end
    return _txt
  end
end

class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.empty? || self =~ (/^(false|f|no|n|0)$/i)
    return false
  end
end

class Fixnum
  def to_bool
    return true if self == 1
    return false if self == 0
    return false
  end
end

class TrueClass
  def to_i;
    1;
  end

  def to_bool;
    self;
  end
end

class FalseClass
  def to_i;
    0;
  end

  def to_bool;
    self;
  end
end

class NilClass
  def to_bool;
    false;
  end
end