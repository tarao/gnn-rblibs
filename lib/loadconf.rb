module LoadConf
  def report(method, e)
    if method.instance_of?(String)
      warn(method)
    elsif method.instance_of?(Proc)
      method.call(e)
    end
  end

  def load(fname, *opt)
    er = opt[0] || {}
    begin
      open(fname) do |src|
        begin
          return instance_eval(src.read.untaint, fname, 1)
        rescue => e
          report(er[:script], e)
        end
      end
    rescue SystemCallError => e
      report(er[:open], e)
    end
  end

  module_function :load, :report
end
