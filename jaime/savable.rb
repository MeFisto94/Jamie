# This class is basically the Parent for everything save-related
module Jaime
    class Savable
        @mutex = Mutex.new;
        @data = {};
        @filename = ""

        ## DON'T CALL FROM USERCODE. NOT THREADSAFE.
        def self.internalSave()
            File.open(@filename, "w") do |f|
                f.write(@data.to_json);
            end
        end

        def self.save()
            @mutex.synchronize do
                self.internalSave();
            end
        end

        ## DON'T CALL FROM USERCODE. NOT THREADSAFE.
        def self.internalLoad()
            if (File.exists?(@filename)) then
                @data = JSON.parse(File.read(@filename))
            else
                @data = {}
            end
        end

        def self.load()
            @mutex.synchronize do
                self.internalLoad();
            end
        end

        def self.setupAndLoad(file)
            @filename = file;
            load();
        end

        ## For internal Manipulations of the data-hash. NEVER CALL ANY VAULT METHOD INSIDE THE LOCK!! (DEADLOCK)
        def self.getLock()
            return @mutex;
        end

        def self.getData()
            return @data;
        end
    end
end