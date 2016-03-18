module Jaime
    class Bot < SlackRubyBot::Bot
    end
    
    ADMIN_USERS = [ "U0P7BK890" ];
    StartCapital = 1000
    BetBaseCapitalMin = 50
    BetBaseCapitalMax = 200
    
    ABOUT = "Jamie \"The Gambler\" v0.0.1 alpha-1 <@dokthar, @darkchaos>\nSee http://github.com/MeFisto94/Jamie\nI'm just your usual Monkey-Next-Door. Well I'm the Croupier of #general...\nUse \"Jamie help\" to see what I'm capable of and use help <topic> to dig further..."
    #HELP = "Nobody will help you, ever. <@#{data.user}>, you're lost! <##{data.channel}> Client: #{client} Data: #{data} Match: #{_match}"
    HELP = "Nobody will help you, ever. You're lost!  (Just kidding :joy:)\n--------------------------------\nI wont react to any comment just by seeing it in chat.\nNonono, Jamie is a good monkey.\nHe will only talk when you say `Jamie <command>` or `@jamie: <command>`\n--------------------------------\n`help <topic>` - Provides further help on the desired topic (If existing)\n`sdk download stats` - Provides you with the stats for the latest published release (might be SNAPSHOT so the stats might look lousy :glitch_crab:)\n`vault <cmd>` - Provides access to your personal :banana: vault (status, transmit). See `help vault` for more information.\n`bet <cmd>` - Allows you to place bets in order to win/lose :banana:s. See `help bet` for more information."
    
    module Commands
        class Debug < SlackRubyBot::Commands::Base
            command 'debug' do |client, data, _match|
                if !(Jaime::Util::isAdmin(data.user)) then
                    Jaime::Util::replyByWhisper(client, data, "Error: You aren't permitted to run this operation");
                    return;
                end
        
                if (_match["expression"] == "this") then
                    Jaime::Util::replyByWhisper(client, data, "Data: '#{data}'\nMatch: '#{_match.pretty_inspect}'\nFirst Name: #{Jaime::Util::getUser(client, data.user).profile.first_name}\nReal Name: #{Jaime::Util::getUser(client, data.user).real_name}\nAccount Name:#{Jaime::Util::getUser(client, data.user).name}\nChannel: #{Jaime::Util::getChannelById(client, data.channel)}", false);
                elsif (_match["expression"] == "list ims") then
                    Jaime::Util::replyByWhisper(client, data, "```\n" + Jaime::Util::getIMs(client).pretty_inspect + "\n```", false);
                elsif (_match["expression"] == "list ims pretty") then
                    ims = Jaime::Util::getIMs(client);
                    str = "User's currently chatting with me\n```";
                    
                    ims.each do |k, v|
                        usr = Jaime::Util::getUser(client, v["user"]);
                        str = "#{str}\n#{usr.real_name} (<@#{usr.id}>) [#{v["is_im"]}] (#{usr.name})";
                        
                        if (v["latest"] != nil && !Jaime::Util::isAdmin(usr.id)) then # Admin's latest could lead to recursion (the ouput of the last debug list ims pretty would be shown here as text
                            str = "#{str} -> #{v["latest"]["text"]}";
                        end
                    end
                    
                    str = "#{str}\n```"
                    Jaime::Util::replyByWhisper(client, data, str, false);
                elsif (/user (.+)/.match(_match["expression"]) != nil) then
                    uId = /user (.+)/.match(_match["expression"])[1];
                    Jaime::Util::replyByWhisper(client, data, "```\n" + Jaime::Util::getUser(client, uId).pretty_inspect + "\n```", false);
                else
                    Jaime::Util::replyByWhisper(client, data, "Error: I don't know `#{_match["expression"]}`", false);
                end
            end
        end
    end
end