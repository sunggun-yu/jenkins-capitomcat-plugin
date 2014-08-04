module Capitomcat

  class CapitomcatUtils

    def initialize(env_map)
      @env_map = env_map
    end

    def is_use_context_update
      return @env_map['use_context_update'].to_bool
    end

    def get_tomcat_work_dir
      return get_base_dir('work')
    end

    def get_tomcat_context_path
      @env_map['tomcat_context_path']
    end

    def get_tomcat_war_file
      if is_use_context_update
        return @env_map['tomcat_doc_base']
      else
        return File.join(@env_map['tomcat_home'], @env_map['tomcat_app_base'], get_tomcat_context_name() + '.war').to_s
      end
    end

    def get_tomcat_context_file
      return "#{get_base_dir('conf')}.xml"
    end

    def get_local_war_file
      return @env_map['local_war_file']
    end

    def get_tomcat_context_name
      if is_use_context_update
        return @env_map['tomcat_context_name']
      else
        local_war_file = get_local_war_file()
        ext_name = File.extname(local_war_file)
        return File.basename(local_war_file, ext_name).to_s
      end
    end

    private
    def get_base_dir(base)
      return File.join(@env_map['tomcat_home'], base, @env_map['tomcat_engine'], @env_map['tomcat_vhost'], get_tomcat_context_name()).to_s
    end

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