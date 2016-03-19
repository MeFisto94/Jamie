module Jaime
    class Bets < Jaime::Savable
        def initialize(filename)
            super(filename);
            @@this = self;
        end
        
        ## Intentionally we would want some Class Variables, but since their shared between all Savables Children
        ## we had to convert it to instance variables and support this() instead (assuming you only have one instance of vault)
        ## If you'd plan to have multiple (banana, apples) then you have to pass the instance somehow.
        def self.this()
            return @@this;
        end
    
        ## Be advised: Using getBets() leads to thousands of bugs because you forget to call save()
        def getBets()
            return getData();
        end
        
        def getJackpot(bet)
            getLock().synchronize do
                return internalGetJackpot(bet);
            end
        end
        
        def internalGetJackpot(bet)
            val = 0;
            bet["bets"].each do |v|
                val += v["amount"]
            end
            
            return val
        end
        
        def handleBetStart(client, data, name, type, description)
            getLock().synchronize do
                if (getBets()[name] != nil) then
                    Jaime::Util::replyByWhisper(client, data, "Error: Can't start that bet because there is already a bet running called #{name}", false);
                elsif ((type != "bool") && (type != "int")) then
                    Jaime::Util::replyByWhisper(client, data, "Error: Unknown Bet Type #{type}", false);
                else
                    if (Jaime::Util::isAdmin(data.user)) then # To prevent abuse
                        baseCapital = Jaime::BetBaseCapitalMin + Random.new.rand(BetBaseCapitalMax - BetBaseCapitalMin);
                    else
                        baseCapital = 0
                    end
                    
                    if (description == nil) then
                        desc = "No description provided";
                    else
                        desc = description;
                    end
                    
                    getBets()[name] = {
                        "name"        => name,
                        "type"        => type,
                        "description" => desc,
                        "bets" => [
                        {
                            "userId" =>        "-1",
                            "amount" => baseCapital,
                            "on"     =>         nil # The bot bets on nil so he's always wrong :D
                        }
                        ]
                    };
                    
                    internalSave();
                    
                    if (type == "bool") then
                        handleBetStartBool(client, data, name, desc, baseCapital);
                    elsif (type == "int") then
                        handleBetStartInt(client, data, name, desc, baseCapital);
                    end
                    
                    client.say(channel: data.channel, text: "say `Jamie bet place #{name} <value> <amount>` to join the fun!");
                end
            end
        end
        
        def handleBetStartBool(client, data, name, description, baseCapital)
            client.say(channel: data.channel, text: ":banana: A new Bet has been started. What is your guess? :banana:\nWill `#{name}` be true or false? Join the Bet!\nDescription: #{description}\nNote: I've placed #{baseCapital}x :banana: in the Pot.");
        end
        
        def handleBetStartInt(client, data, name, description, baseCapital)
            client.say(channel: data.channel, text: ":banana: A new Bet has been started. What is your guess? :banana:\nWhat number will  `#{name}` be? Join the Bet!\nDescription: #{description}\nNote: I've placed #{baseCapital}x :banana: in the Pot.\nThe closest guess will win (and when there are multiple winners, the win will be shared based on the input)");
        end
        
        def handleBetPlace(client, data, bet_name, value, amount)
            if (amount <= 0) then
                Jaime::Util::replyByWhisper(client, data, "Error: Your betting amount has to be > 0!", false);
                return;
            end
            
            getLock().synchronize do
                if (getBets()[bet_name] == nil) then
                    Jaime::Util::replyByWhisper(client, data, "Error: Can't place your bet because there is no bet running called #{bet_name}. Use `bet list` to see active bets.", false);
                else
                    bet = getBets()[bet_name];
                    
                    if internalIsBetBoolean(bet) then
                        if isValueBoolean(value) then
                            handleBetPlaceBool(client, data, bet, value, amount);
                        else
                            Jaime::Util::replyByWhisper(client, data, "Error: Can't place your bet because the bet is booleanic (true/false) but you didn't bet on a boolean.", false);
                        end
                    elsif internalIsBetInteger(bet) then
                        if isValueInteger(value) then
                            handleBetPlaceInt(client, data, bet, value, amount);
                        else
                            Jaime::Util::replyByWhisper(client, data, "Error: Can't place your bet because the bet is of type integer (numbers) but you didn't bet on a number.", false);
                        end
                    end
                end
            end
        end
        
        ## This actually handles/adds the bet, but handleBetPlace() is more of the parser (if you don't type a bool on an int bet or smth)
        ## handleBetPlaceInternal wouldn't care about that fact. Note also: Internal means suround it by the LOCK!
        def handleBetPlaceInternal(client, data, bet, value, amount)
            if internalGetBetsByUserId(bet, data.user) != nil then # Try to adjust current bets
                usr_bets = internalGetBetsByUserId(bet, data.user);
                usr_bets.each do |b|
                    if ((b["on"] == value) && (amount != 0)) then # In case there would be multiple bets on "value", only use the first (Note: There shouldn't be multiple bets on value, except when not properly modifying bets[])
                        b["amount"] += amount;
                        Jaime::Util::replyByWhisper(client, data, "[GAMBLING]: Your bet on #{value} has been updated. Current input: #{b["amount"]}x :banana:", false);
                        
                        vault = Jaime::Vault::this().getUserVaultEx(client, data.user);
                        Jaime::Vault::this().adjustAccountBalance(vault, -amount);
                        Jaime::Util::WhisperUser(client, data.user, "[VAULT]: You just paid #{amount}x :banana: to participate in the Bet `#{bet["name"]}`!\nNew Balance: #{Jaime::Vault::this().getAccountBalance(vault).to_s}x :banana:");
                        Jaime::Vault::this().save();
                        amount = 0;
                        internalSave();
                    end
                end
            end
            
            if (amount > 0) then # Probably a bet on something new
                bet["bets"] += [ {"userId" => data.user, "amount" => amount, "on" => value} ];
                Jaime::Util::replyByWhisper(client, data, "[GAMBLING]: Your bet on #{value} has been successfully placed. Current input: #{amount}x :banana:", false);
                
                vault = Jaime::Vault::this().getUserVaultEx(client, data.user);
                Jaime::Vault::this().adjustAccountBalance(vault, -amount);
                Jaime::Util::WhisperUser(client, data.user, "[VAULT]: You just paid #{amount}x :banana: to participate in the Bet `#{bet["name"]}`!\nNew Balance: #{Jaime::Vault::this().getAccountBalance(vault).to_s}x :banana:");
                Jaime::Vault::this().save();
                internalSave();
            end
        end
        
        def handleBetPlaceBool(client, data, bet, value, amount)
            handleBetPlaceInternal(client, data, bet, value, amount);
        end
        
        def handleBetPlaceInt(client, data, bet, value, amount)
            handleBetPlaceInternal(client, data, bet, value, amount);
        end
        
        def handleBetEnd(client, data, bet_name, value)
            getLock().synchronize do
                if (getBets()[bet_name] == nil) then
                    client.say(channel: data.channel, text: "Error: Cannot End the Bet #{bet_name} since there is currently no such bet running... :see_no_evil:");
                else
                    bet = getBets()[bet_name];
                    if (internalIsBetInteger(bet)) then
                        if (isValueInteger(value)) then
                            client.say(channel: data.channel, text: "TODO: IMPLEMENT!");
                            internalRemoveFromData(bet_name);
                            internalSave();
                        else
                            client.say(channel: data.channel, text: "Error: Cannot End the Bet #{bet_name} because you entered a bool type but it's not of type bool...");
                        end
                    elsif (internalIsBetBoolean(bet)) then
                        if (isValueBooleanOrRandom(value)) then
                            
                            if (value == "random") then
                                value = ["true", "false"].sample
                            end
                            
                            jackpot = internalGetJackpot(bet);
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
                            
                            str = "The right answer was `#{value}`. Here comes the List of Winners:\n```"
                            
                            winners.each do |w|
                                percentage = w["amount"].to_f / sum_input_winners.to_f;
                                str = "#{str}\n<@#{w["userId"]}> #{(percentage * jackpot).round.to_s}x Banana by betting #{w["amount"]} on #{w["on"]}"
                                vault = Jaime::Vault::this().getUserVaultEx(client, w["userId"]);
                                Jaime::Vault::this().adjustAccountBalance(vault, (percentage * jackpot).round);
                                Jaime::Util::WhisperUser(client, w["userId"], "[VAULT]: Yeah! You have just won #{(percentage * jackpot).round.to_s}x :banana: by Gambling. Enjoy those delicious Bananas!\nNew Balance: #{Jaime::Vault::this().getAccountBalance(vault).to_s}x :banana:");
                                Jaime::Vault::this().save();
                            end
                            
                            str = "#{str}\n```\nThanks for Playing :glitch_crab:";
                            client.say(channel: data.channel, text: str);
                            
                            internalRemoveFromData(bet_name);
                            internalSave();
                        else
                            client.say(channel: data.channel, text: "Error: Cannot End the Bet #{bet_name} because you entered a non-bool type but it's of type bool...");
                        end
                    end # internalIsBetBoolean
                end # else (bet is running with that name)
            end # synchronize
        end # def
        
        ## REGION isBetXYZ()
        def isBetBoolean(bet)
            getLock().synchronize do
                return internalIsBetBoolean(bet);
            end
        end
        
        def internalIsBetBoolean(bet)
            return bet["type"] == "bool";
        end
        
        def isBetInteger(bet)
            getLock().synchronize do
                return internalIsBetInteger(bet);
            end
        end
        
        def internalIsBetInteger(bet)
            return bet["type"] == "int";
        end
        
        ## REGION isValueXYZ()
        def isValueBoolean(val)
            return val == "true" || val == "false";
        end
        
        def isValueBooleanOrRandom(val)
            return isValueBoolean(val) || val == "random";
        end
        
        def isValueInteger(val)
            return (/\d+/.match(val) != nil);
        end
        
        ## REGION getXYZByUVW
        def getBetsByUserId(bet, userId)
            getLock().synchronize do
                return internalGetBetsByUserId(bet, userId);
            end
        end

        def internalGetBetsByUserId(bet, userId)
            return bet["bets"].select{|value| value["userId"] == userId };
        end
    end
end