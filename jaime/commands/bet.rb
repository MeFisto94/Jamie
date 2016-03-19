module Jaime
    module Commands
        class Bet < SlackRubyBot::Commands::Base
            command 'bet' do |client, data, _match|
                if /start (.+) (int|bool)( (.+))?/.match(_match["expression"]) then
                    # Start a new bet...
                    matches = /start (.+) (int|bool)( (.+))?/.match(_match["expression"]);
                    Jaime::Bets::this().handleBetStart(client, data, matches[1], matches[2], matches[4])
                elsif /place (.+) (\d+|\w+) (\d+)/.match(_match["expression"]) then
                    matches = /place (.+) (\d+|\w+) (\d+)/.match(_match["expression"]);
                    bet_name = matches[1]
                    value = matches[2]
                    amount = matches[3].to_i
                    
                    Jaime::Bets::this().handleBetPlace(client, data, bet_name, value, amount);
                elsif /end (.+) (\d+|\w+)/.match(_match["expression"]) then
                    matches = /end (.+) (\d+|\w+)/.match(_match["expression"]);
                    bet_name = matches[1];
                    value = matches[2];
                    
                    Jaime::Bets::this().handleBetEnd(client, data, bet_name, value);


                elsif /list/.match(_match["expression"]) then
                    str = ":banana: Currently running Bets: :banana:\n```"
                    
                    Jaime::Bets::this().getLock().synchronize do
                        Jaime::Bets::this().getBets().each do |k, v|
                            if v != nil then
                                str = "#{str}\n#{k} => type=#{v["type"]}, jackpot=#{Jaime::Bets::this().internalGetJackpot(v)}, description=\"#{v["description"]}\"";
                            end
                        end
                    end

                    str = "#{str}\n```"
                    client.say(channel: data.channel, text: str);
                end
            end
        end
    end
end