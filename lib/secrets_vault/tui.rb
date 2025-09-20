require "io/console"

class SecretsVault
  module TUI
    extend self

    def ask(prompt, echo: true, confirm: false, io: $stdin)
      reader = -> {
        if echo
          io.gets
        else
          io.noecho(&:gets).tap { puts }
        end.to_s.chomp
      }

      print prompt
      answer = reader.call

      if confirm
        print "(confirm) #{prompt}"
        confirmation = reader.call
        raise Error, "Passphrase confirmation doesn't match" if confirmation != answer
      end

      answer
    end
  end
end
