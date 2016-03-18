module Jaime
    module Commands
        class Vault < SlackRubyBot::Commands::Base
            command 'vault' do |client, data, _match|
                if (_match["expression"] == nil) then
                    Jaime::Util::replyByWhisper(client, data, "Missing Parameter. See `help vault` for more information", false);
                elsif (_match["expression"] == "status") then
                    usr_vault = Jaime::Vault.getUserVaultEx(client, data.user);
                    Jaime::Util::replyByWhisper(client, data, "Your current Account Balance is #{usr_vault["balance"]}x :banana:", false);
                elsif (/admin (add|remove)( <@(U.*)>)? (\d+)/.match(_match["expression"]))
                    matches = /admin (add|remove)( <@(U.*)>)? (\d+)/.match(_match["expression"]);
                    amount = matches[4].to_i;
                    
                    if (matches[1] == "remove") then
                        amount *= -1;
                    end
                    
                    if (matches[2] == nil) then
                        userId = data.user;
                    else
                        userId = matches[3]; # Note: When you link someone it'll be <@USERID> (So no need to look it up)
                    end
        
                    vault = Jaime::Vault::getUserVaultEx(client, userId)
                    Jaime::Vault::adjustAccountBalance(vault, amount)

                    Jaime::Util::WhisperUser(client, userId, "[ADMIN]: Your Account Balance has been adjusted by #{amount.to_s}. New Balance: #{Jaime::Vault::getAccountBalance(vault).to_s}x :banana:");
                    
                    if (userId != data.user) then # Notify admin
                        Jaime::Util::replyByWhisper(client, data, "[ADMIN]: <@#{userId}>'s Account Balance has been adjusted by #{amount.to_s}. New Balance: #{Jaime::Vault::getAccountBalance(vault).to_s}x :banana:", false);
                    end

                    Jaime::Vault::save()
                elsif (/transmit <@(U.*)> (\d+)/.match(_match["expression"]))
                    matches = /transmit <@(U.*)> (\d+)/.match(_match["expression"]);
                    user = matches[1];
                    amount = matches[2].to_i;
                    
                    if (amount < 0) then # Not even called since the regexp doesn't allow the "-"
                        Jaime::Util::replyByWhisper(client, data, "Error: Can't transmit a negative value (but nice attempt :P", false);
                        return;
                    end

                    src_vault = Jaime::Vault::getUserVaultEx(client, data.user);
                    target_vault = Jaime::Vault::getUserVaultEx(client, user);

                    if (amount > Jaime::Vault::getAccountBalance(src_vault)) then # We use getBalance here to be thread safe
                        Jaime::Util::replyByWhisper(client, data, "Error: Can't transmit the #{amount.to_s}x :banana: to <@#{user}> because you don't even have that much :banana:....", false);
                        return;
                    end

                    Jaime::Vault::adjustAccountBalance(src_vault, -amount);
                    Jaime::Vault::adjustAccountBalance(target_vault, amount);

                    Jaime::Util::replyByWhisper(client, data, "YEAH! Transmission sucessful. #{amount.to_s}x :banana: have been transmitted to <@#{user}> :glitch_crab:. Your new Balance is: #{Jaime::Vault::getAccountBalance(src_vault)}x :banana:", false);
                    Jaime::Util::WhisperUser(client, user, "YEAH! You've just recieved a transmission of #{amount.to_s}x :banana: from <@#{data.user}> :glitch_crab:. Your new Balance is: #{Jaime::Vault::getAccountBalance(target_vault)}x :banana:");
                else
                    Jaime::Util::replyByWhisper(client, data, _match["expression"], false);
                end
            end
        end
    end

    class Vault
        @@mutex = Mutex.new;
        @@data = {};
        
        def self.getUserVaultEx(client, userId)
            usr_vault = getUserVault(userId);
            if (usr_vault == nil) then
                Jaime::Util::WhisperUser(client, userId, "Warning: Couldn't get your Vault.\nSeems like this is your first time, huh?\nI just created a brand new shiny vault for you.\nYou've been given #{Jaime::StartCapital}x :banana: by the great MonkeyGod.");
                usr_vault = createUserVault(userId, Jaime::StartCapital);
            end

            return usr_vault;
        end

        def self.getUserVault(userId)
            @@mutex.synchronize do
                return @@data[userId];
            end
        end

        def self.createUserVault(userId, capital)
            usr_vault = nil;
            @@mutex.synchronize do
                @@data[userId] = { "userId" => userId, "balance" => capital }
                internalSave();
                usr_vault = @@data[userId];
            end

            return usr_vault;
        end

        def self.getAccountBalance(vault)
            if (vault == nil) then
                return 0;
            else
                bal = 0; # so it's available inside the block and won't be threaded as block-local-var
                @@mutex.synchronize do
                    bal = vault["balance"];
                end
                return bal;
            end
        end

        def self.setAccountBalance(vault, balance)
            if (vault != nil) then
                @@mutex.synchronize do
                    vault["balance"] = balance;
                    internalSave()
                end
            end
        end

        def self.adjustAccountBalance(vault, adjustment)
            if (vault != nil) then
                @@mutex.synchronize do
                    vault["balance"] += adjustment;
                    internalSave()
                end
            end
        end

        ## DON'T CALL FROM USERCODE. NOT THREADSAFE.
        def self.internalSave()
            File.open("vault.json", "w") do |f|
                f.write(@@data.to_json);
            end
        end

        def self.save()
            @@mutex.synchronize do
                self.internalSave();
            end
        end

        ## DON'T CALL FROM USERCODE. NOT THREADSAFE.
        def self.internalLoad()
            if (File.exists?('vault.json')) then
                @@data = JSON.parse(File.read('vault.json'))
            else
                @@data = {}
            end
        end

        def self.load()
            @@mutex.synchronize do
                self.internalLoad();
            end
        end

        ## For internal Manipulations of the data-hash. NEVER CALL ANY VAULT METHOD INSIDE THE LOCK!! (DEADLOCK)
        def self.getLock()
            return @@mutex;
        end

    end
end