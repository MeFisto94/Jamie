module Jaime
    module Commands
        class Vault < SlackRubyBot::Commands::Base
            command 'vault' do |client, data, _match|
                if (_match["expression"] == nil) then
                    Jaime::Util::replyByWhisper(client, data, "Missing Parameter. See `help vault` for more information", false);
                elsif (_match["expression"] == "status") then
                    usr_vault = Jaime::Vault::this().getUserVaultEx(client, data.user);
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

                    vault = Jaime::Vault::this().getUserVaultEx(client, userId)
                    Jaime::Vault::this().adjustAccountBalance(vault, amount)

                    Jaime::Util::WhisperUser(client, userId, "[ADMIN]: Your Account Balance has been adjusted by #{amount.to_s}. New Balance: #{Jaime::Vault::this().getAccountBalance(vault).to_s}x :banana:");

                    if (userId != data.user) then # Notify admin
                        Jaime::Util::replyByWhisper(client, data, "[ADMIN]: <@#{userId}>'s Account Balance has been adjusted by #{amount.to_s}. New Balance: #{Jaime::Vault::this().getAccountBalance(vault).to_s}x :banana:", false);
                    end

                    Jaime::Vault::this().save()
                elsif (/transmit <@(U.*)> (\d+)/.match(_match["expression"]))
                    matches = /transmit <@(U.*)> (\d+)/.match(_match["expression"]);
                    user = matches[1];
                    amount = matches[2].to_i;

                    if (amount < 0) then # Not even called since the regexp doesn't allow the "-"
                        Jaime::Util::replyByWhisper(client, data, "Error: Can't transmit a negative value (but nice attempt :P", false);
                        return;
                    end

                    src_vault = Jaime::Vault::this().getUserVaultEx(client, data.user);
                    target_vault = Jaime::Vault::this().getUserVaultEx(client, user);

                    if (amount > Jaime::Vault::this().getAccountBalance(src_vault)) then # We use getBalance here to be thread safe
                        Jaime::Util::replyByWhisper(client, data, "Error: Can't transmit the #{amount.to_s}x :banana: to <@#{user}> because you don't even have that much :banana:....", false);
                        return;
                    end

                    Jaime::Vault::this().adjustAccountBalance(src_vault, -amount);
                    Jaime::Vault::this().adjustAccountBalance(target_vault, amount);

                    Jaime::Util::replyByWhisper(client, data, "YEAH! Transmission sucessful. #{amount.to_s}x :banana: have been transmitted to <@#{user}> :glitch_crab:. Your new Balance is: #{Jaime::Vault::this().getAccountBalance(src_vault)}x :banana:", false);
                    Jaime::Util::WhisperUser(client, user, "YEAH! You've just recieved a transmission of #{amount.to_s}x :banana: from <@#{data.user}> :glitch_crab:. Your new Balance is: #{Jaime::Vault::this().getAccountBalance(target_vault)}x :banana:");
                else
                    Jaime::Util::replyByWhisper(client, data, "<@{data.user}> I'm sorry but I don't understand. Maybe you want to see `help vault`?", false);
                end
            end
        end
    end
end