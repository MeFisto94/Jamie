module Jaime
    module Commands
        class Bet < SlackRubyBot::Commands::Base
            command 'bet' do |client, data, _match|
                client.say(channel: data.channel, text: '4')
            end
        end
    end
end