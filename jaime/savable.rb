# This class is basically the Parent for everything save-related
module Jaime
    class Savable
        def initialize(file)
            @mutex = Mutex.new;
            @data = {};
            @filename = file;
        end
        
        ## DON'T CALL FROM USERCODE. NOT THREADSAFE.
        def internalSave()
            File.open(@filename, "w") do |f|
                f.write(@data.to_json);
            end
        end

        def save()
            @mutex.synchronize do
                internalSave();
            end
        end

        ## DON'T CALL FROM USERCODE. NOT THREADSAFE.
        def internalLoad()
            if (File.exists?(@filename)) then
                @data = JSON.parse(File.read(@filename))
            else
                @data = {}
            end
        end

        def load()
            @mutex.synchronize do
                internalLoad();
            end
        end

        ## For internal Manipulations of the data-hash. NEVER CALL ANY VAULT METHOD INSIDE THE LOCK!! (DEADLOCK)
        def getLock()
            return @mutex;
        end

        def getData()
            return @data;
        end
        
        def internalRemoveFromData(key)
            @data.delete(key)
        end
        
        def removeFromData(key)
            getLock().synchronize do
                internalRemoveFromData(key);
            end
        end
    end
end