require 'rbconfig'

module RbConfig
  cmd = File.join(CONFIG['bindir'], CONFIG['ruby_install_name'])
  CONFIG['ruby_command'] = cmd.sub(/.*\s.*/m, '"\&"')

  def program_name
    return (defined?(ExerbRuntime) && ExerbRuntime.filepath) || $0
  end

  def self_invoke_command
    cmd = File.expand_path(program_name)
    cmd.sub(/.*\s.*/m, '"\&"')
    ext = Config::CONFIG['EXEEXT']
    unless ext.length != 0 && program_name =~ /#{ext}$/
      cmd = CONFIG['ruby_command'] + ' ' + cmd
    end
    return cmd
  end

  module_function :program_name, :self_invoke_command
end
