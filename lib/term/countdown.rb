require 'termios'

module Term
  def countdown(time, *args, &block)
    wait, br = args
    if args[0].instance_of?(Hash)
      wait = args[0][:wait]
      br = args[0][:br]
    end
    wait ||= 0.05
    br ||= '[\r\n]'
    default = proc do |elapse|
      t = time - elapse
      t = 0 if t < 0
      t *= 1000
      $stdout.flush
      printf("\r%6d", t.to_i)
    end
    block = default unless block

    old = Termios.tcgetattr($stdin)
    tio = Termios.tcgetattr($stdin)
    tio.cc[Termios::VMIN] = 1
    tio.cc[Termios::VTIME] = 0
    tio.iflag &= ~Termios::ICRNL  # see libcurses/screen/cbreak.c
    tio.lflag &= ~Termios::ICANON
    tio.lflag &= ~Termios::ECHO
    Termios.tcsetattr($stdin, Termios::TCSANOW, tio)

    begin
      s = Time.now.to_f
      e = s + time.to_f
      while true
        now = Time.now.to_f
        block.call(now - s)
        break if now >= e
        sleep(wait)
        s = $stdin.read_nonblock(1) rescue next
        break if s =~ /#{br}/
          return false
      end
    ensure
      Termios.tcsetattr($stdin, Termios::TCSANOW, old)
    end

    return true
  end

  module_function :countdown
end
