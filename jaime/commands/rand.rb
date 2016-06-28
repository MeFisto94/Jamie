module Jaime
    module Commands
        class Rand < SlackRubyBot::Commands::Base
            def rollDices(nbDices, nbFaces)
                res = Array.new
                nbDices.abs.times do
                    res.push Random.new.rand(1..nbFaces.abs);
                end
                return res;
            end

            command 'rand' do |client, data, _match|
                if (_match["expression"] == nil) then
                    str = "Rolling 1D100 !\n"
                    str += rollDices(1, 100).to_s;
                    client.say(channel: data.channel, text: str);
                elsif (/d|D/.match(_match["expression"]) ) then
                    dicesArgs = _match["expression"].split(/d|D/)
                    if(dicesArgs.length == 2) then
                        str += rollDices(dicesArgs[0].to_i,dicesArgs[1].to_i).to_s;
                        client.say(channel: data.channel, text: str);
                    else
                        Jaime::Util::replyByWhisper(client, data, "Usage: `rand <nbDices>D<nbFaces>`");
                    end
                else
                    Jaime::Util::replyByWhisper(client, data, "Usage: `rand <nbDices>D<nbFaces>`");
                end
            end
        end
    end
end


