module Jaime
    class Vault < Jaime::Savable
        @@this = nil; # Has to happen on class level and not in Savable.
        
        def initialize(filename)
            super(filename);
            @@this = self;
        end
        
        def self.this()
            return @@this;
        end
        
        def getUserVaultEx(client, userId)
            usr_vault = getUserVault(userId);
            if (usr_vault == nil) then
                Jaime::Util::WhisperUser(client, userId, "Warning: Couldn't get your Vault.\nSeems like this is your first time, huh?\nI just created a brand new shiny vault for you.\nYou've been given #{Jaime::StartCapital}x :banana: by the great MonkeyGod.");
                usr_vault = createUserVault(userId, Jaime::StartCapital);
            end

            return usr_vault;
        end

        def getUserVault(userId)
            getLock().synchronize do
                return getData()[userId];
            end
        end

        def createUserVault(userId, capital)
            usr_vault = nil;
            getLock().synchronize do
                getData()[userId] = { "userId" => userId, "balance" => capital }
                internalSave();
                usr_vault = getData()[userId];
            end

            return usr_vault;
        end

        def getAccountBalance(vault)
            if (vault == nil) then
                return 0;
            else
                bal = 0; # so it's available inside the block and won't be threaded as block-local-var
                getLock().synchronize do
                    bal = vault["balance"];
                end
                return bal;
            end
        end

        def setAccountBalance(vault, balance)
            if (vault != nil) then
                getLock().synchronize do
                    vault["balance"] = balance;
                    internalSave()
                end
            end
        end

        def adjustAccountBalance(vault, adjustment)
            if (vault != nil) then
                getLock().synchronize do
                    vault["balance"] += adjustment;
                    internalSave()
                end
            end
        end
    end
end