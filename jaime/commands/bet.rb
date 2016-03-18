module Jaime
    module Commands
        class Bet < SlackRubyBot::Commands::Base
            command 'bet' do |client, data, _match|
                if /start (\w+) (int|bool)/.match(_match["expression"]) then
                    # Start a new bet...
                    matches = /start (\w+) (int|bool)/.match(_match["expression"]);
                    
                    Jaime::Bets.getLock().synchronize do # Fuck all this API shit, we do it directly :P
                        if (Jaime::Bets.getBets()[matches[1]] != nil) then
                            Jaime::Util::replyByWhisper(client, data, "Error: Can't start that bet because there is already a bet running called #{matches[1]}", false);
                        else
                            BaseCapital = Jaime::BetBaseCapitalMin + Random.new.rand(BetBaseCapitalMax - BetBaseCapitalMin);
                            Jaime::Bets::getBets()[matches[1]] = {
                                "name" => matches[1],
                                "type" => matches[2],
                                "bets" => [
                                    {
                                        "userId" => "-1",
                                        "amount" => BaseCapital,
                                        "on" => nil # The bot bets on nil so he's always wrong :D
                                    }
                                ]
                            };
                            
                            Jaime::Bets::internalSave();
                            
                            client.say(channel: data.channel, text: ":banana: A new Bet has been started. What is your guess? :banana:\nWhat Value will #{matches[1]} have? Join the Bet!\nNote: I've placed #{BaseCapital}x :banana: in the Pot.");
                        end
                    end
                elsif /place (\w+) (\d+|\w+) (\d+)/.match(_match["expression"]) then
                    matches = /place (\w+) (\d+|\w+) (\d+)/.match(_match["expression"]);
                    bet_name = matches[1]
                    value = matches[2]
                    amount = matches[3].to_i
                    
                    if (amount <= 0) then
                        Jaime::Util::replyByWhisper(client, data, "Error: Your betting amount has to be > 0!", false);
                        return;
                    end
                    
                    Jaime::Bets.getLock().synchronize do
                        if (Jaime::Bets.getBets()[bet_name] == nil) then
                            Jaime::Util::replyByWhisper(client, data, "Error: Can't place your bet because there is no bet running called #{bet_name}", false);
                        else
                            bet = Jaime::Bets.getBets()[bet_name];
                            
                            if Jaime::Bets.internalIsBetBoolean(bet) then
                                if Jaime::Bets.isValueBoolean(value) then
                                    if Jaime::Bets.internalGetBetsByUserId(bet, data.user) != nil then # Try to adjust current bets
                                        usr_bets = Jaime::Bets.internalGetBetsByUserId(bet, data.user);
                                        
                                        usr_bets.each do |b|
                                            if (b["on"] == value) then
                                                b["amount"] += amount;
                                                Jaime::Util::replyByWhisper(client, data, "Note: Your bet on #{value} has been updated. Current input: #{b["amount"]}x :banana:");
                                                
                                                vault = Jaime::Vault::getUserVaultEx(client, data.user);
                                                Jaime::Vault::adjustAccountBalance(vault, -amount);
                                                Jaime::Util::WhisperUser(client, data.user, "[GAMBLING]: You just paid #{amount}x :banana: to participate in the Bet `#{bet_name}`!\nNew Balance: #{Jaime::Vault::getAccountBalance(vault).to_s}x :banana:");
                                                Jaime::Vault.Save(); #TODO: FIX ME (Maybe make mutex no class variable of Savable, atleast so it's now VAULT or BET)

                                                amount = 0;
                                                Jamie::Bets.internalSave();
                                            end
                                        end
                                    end

                                    if (amount > 0) then # Probably a bet on something new
                                        bet["bets"] += [ {"userId" => data.user, "amount" => amount, "on" => value} ];
                                        Jaime::Util::replyByWhisper(client, data, "Note: Your bet on #{value} has been successfully placed. Current input: #{amount}x :banana:", false);
                                        
                                        vault = Jaime::Vault::getUserVaultEx(client, data.user);
                                        Jaime::Vault::adjustAccountBalance(vault, -amount);
                                        Jaime::Util::WhisperUser(client, data.user, "[GAMBLING]: You just paid #{amount}x :banana: to participate in the Bet `#{bet_name}`!\nNew Balance: #{Jaime::Vault::getAccountBalance(vault).to_s}x :banana:");
                                        Jaime::Vault.Save();
                                        Jaime::Bets.internalSave();
                                    end
                                else
                                    Jaime::Util::replyByWhisper(client, data, "Error: Can't place your bet because the bet is booleanic (true/false) but you didn't bet on a boolean.", false);
                                end
                            elsif Jaime::Bets.internalIsBetInteger(bet) then
                                if Jaime::Bets.isValueInteger(value) then
                                    # Handle with care
                                else
                                    Jaime::Util::replyByWhisper(client, data, "Error: Can't place your bet because the bet is of type integer (numbers) but you didn't bet on a number.", false);
                                end
                            end
                        end
                    end
                elsif /end (\w+) (\d+|\w+)/.match(_match["expression"]) then
                    matches = /end (\w+) (\d+|\w+)/.match(_match["expression"]);
                    bet_name = matches[1];
                    value = matches[2];

                    Jaime::Bets.getLock().synchronize do
                        if (Jaime::Bets.getBets()[bet_name] == nil) then
                            client.say(channel: data.channel, text: "Error: Cannot End the Bet #{bet_name} since there is currently no such bet running... :see_no_evil:");
                        else
                            bet = Jaime::Bets.getBets()[bet_name];
                            if (Jaime::Bets.internalIsBetInteger(bet)) then
                                if (Jaime::Bets.isValueInteger(value)) then
                                    client.say(channel: data.channel, text: "TODO: IMPLEMENT!");
                                    Jaime::Bets.getBets()[bet_name] = nil;
                                    Jaime::Bets.internalSave();
                                else
                                    client.say(channel: data.channel, text: "Error: Cannot End the Bet #{bet_name} because you entered a bool type but it's not of type bool...");
                                end
                            elsif (Jaime::Bets.internalIsBetBoolean(bet)) then
                                if (Jaime::Bets.isValueBoolean(value)) then
                                    jackpot = Jaime::Bets.internalGetJackpot(bet);
                                    client.say(channel: data.channel, text: ":banana: Ring Ding Ding! Rien ne vas plus.... :banana:");
                                    client.say(channel: data.channel, text: "The Bet `#{bet_name}` has been finished. The Jackpot is #{jackpot}x :banana:");
                                    
                                    winners = [];
                                    sum_input_winners = 0;
                                    bet["bets"].each do |v|
                                        if (v["userId"] != "-1") then
                                            if (v["on"] == value) then
                                                winners += [ v ];
                                                sum_input_winners += v["amount"];
                                            end
                                        end
                                    end
                                    
                                    str = "Here comes the List of Winners:\n```"
                                    
                                    winners.each do |w|
                                        percentage = w["amount"] / sum_input_winners;
                                        str = "#{str}\n<@#{w["userId"]}> #{percentage * jackpot}x Banana by betting #{w["amount"]} on #{w["on"]}"
                                        vault = Jaime::Vault::getUserVaultEx(client, userId);
                                        Jaime::Vault::adjustAccountBalance(vault, (percentage * jackpot));
                                        Jaime::Util::WhisperUser(client, userId, "[GAMBLING]: Yeah! You have just won #{percentage * jackpot}x :banana: by Gambling. Enjoy those delicious Bananas!.\nNew Balance: #{Jaime::Vault::getAccountBalance(vault).to_s}x :banana:");
                                        Jaime::Vault.save();
                                    end
                                    
                                    str = "#{str}\n```\nThanks for Playing :glitch_crab:";
                                    client.say(channel: data.channel, text: str);
                                    
                                    Jaime::Bets.getBets()[bet_name] = nil;
                                    Jaime::Bets.internalSave();
                                else
                                    client.say(channel: data.channel, text: "Error: Cannot End the Bet #{bet_name} because you entered a non-bool type but it's of type bool...");
                                end
                            end
                        end
                    end
                elsif /list/.match(_match["expression"]) then
                    str = ":banana: Currently running Bets: :banana:\n```"
                    
                    Jaime::Bets.getLock().synchronize do
                        Jaime::Bets.getBets().each do |k, v|
                            if v != nil then
                                str = "#{str}\n#{k} => type=#{v["type"]}, jackpot=#{Jaime::Bets.internalGetJackpot(v)}";
                            end
                        end
                    end

                    str = "#{str}\n```"
                    client.say(channel: data.channel, text: str);
                end
            end
        end
    end

    class Bets < Jaime::Savable
        
        ## Be advised: Using getBets() leads to thousands of bugs because you forget to call save()
        def self.getBets()
            return getData();
        end

        def self.getJackpot(bet)
            getLock().synchronize do
                return internalGetJackpot(bet);
            end
        end

        def self.internalGetJackpot(bet)
            val = 0;
            puts bet["bets"].pretty_inspect
            bet["bets"].each do |v|
                val += v["amount"]
            end

            return val
        end

        ## REGION isBetXYZ()
        def self.isBetBoolean(bet)
            getLock().synchronize do
                return internalIsBetBoolean(bet);
            end
        end

        def self.internalIsBetBoolean(bet)
            return bet["type"] == "bool";
        end

        def self.isBetInteger(bet)
            getLock().synchronize do
                return internalIsBetInteger(bet);
            end
        end

        def self.internalIsBetInteger(bet)
            return bet["type"] == "int";
        end

        ## REGION isValueXYZ()
        def self.isValueBoolean(val)
            return val == "true" || val == "false";
        end

        def self.isValueInteger(val)
            return (/\d+/.match(val) != nil);
        end

        ## REGION getXYZByUVW
        def self.getBetsByUserId(bet, userId)
            getLock().synchronize do
                return internalGetBetsByUserId(bet, userId);
            end
        end

        def self.internalGetBetsByUserId(bet, userId)
            return bet.select{|value| value["userId"] == userId };
        end
    end
end