module Capitomcat

  class EnvUtils

    def initialize(task, env_vars)
      @task = task
      @env_vars = env_vars
    end

    # Substitute the instance variable with environment variable in Jenkins Build instance.
    def substitute_env_vars(txt)
      _txt = txt
      @env_vars.each do |env_key, env_value|
        _txt = _txt.gsub("$#{env_key}", env_value)
      end
      return _txt
    end

    # Generate Capitomcat environment variables hash with instance variable substitution
    def get_substituted_env_map
      env_map = Hash.new
      @task.instance_variables.each do |v|
        value_of_symbol = @task.instance_variable_get(v)
        # Some instance variables are Hash type.
        if value_of_symbol.is_a?(Hash)
          env_map[v.to_s.gsub('@', '')] = true
          value_of_symbol.each do |sub_hash_key, sub_hash_value|
            # Replace the value for the key of Hash
            env_map[sub_hash_key.to_s.gsub('@', '')] = substitute_env_vars(sub_hash_value)
          end
        else
          # Replace the value for the Symbol of the instance variable
          env_map[v.to_s.gsub('@', '')] = substitute_env_vars(value_of_symbol)
        end
      end
      return env_map
    end
  end
end