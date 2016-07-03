module Jaime
    module Commands
        class Roll < SlackRubyBot::Commands::Base
            def rollDices(nbDices, nbFaces)
                res = Array.new
                nbDices.abs.times do
                    res.push Random.new.rand(1..nbFaces.abs);
                end
                return res;
            end

            command 'roll' do |client, data, _match|
                if (_match["expression"] == nil) then
                    str = "Rolling 1 100-faced dice !\n"
                    str += Jaime::Commands::Roll::rollDices(1, 100).to_s;
                    client.say(channel: data.channel, text: str);
                elsif (/^\d+(d|D| )\d+$/.match(_match["expression"].strip) ) then
                    dicesArgs = _match["expression"].strip.split(/d|D| /)
                    if(dicesArgs.length == 2) then
                        str = "Rolling " + dicesArgs[0] + " " + dicesArgs[1]+ "-faced dice" + (dicesArgs[0].to_i > 1 ? "s" : "") + " for you !\n"
                        str += Jaime::Commands::Roll::rollDices(dicesArgs[0].to_i,dicesArgs[1].to_i).to_s;
                        client.say(channel: data.channel, text: str);
                    else
                        Jaime::Util::replyByWhisper(client, data, "Usage: `roll <nbDices>D<nbFaces>`",false);
                    end
                else
                    Jaime::Util::replyByWhisper(client, data, "Usage: `roll <nbDices>D<nbFaces>`",false);
                end
            end
        end
    end
end


