module Jaime
    class Util
        def self.getUser(client, userId)
            return client.users[userId];
        end

        def self.getUserByUsername(client, username)
            return client.users.find{|key, hash| hash["name"] == username }[1];
        end

        def self.isAdmin(userId)
            return Jaime::ADMIN_USERS.include?(userId);
        end

        def self.getIMs(client)
            # return client.web_client.im_list()["ims"];
            return client.ims;
        end

        def self.getIMByUserId(client, userId)
            im = getIMs(client).find{|hash, value| value["user"] == "#{userId}" };
            if im == nil then
                return nil;
            else
                return im[1];
            end
        end

        def self.getIMByChannelId(client, chId)
            # return getIMs(client).find{|hash| hash["id"] == "#{chId}" }[0]; # This is needed when we have it from the web
            return getIMs(client)[chId];
        end

        def self.getIMChannelId(client, userId)
            a = getIMByUserId(client, userId);

            if (a != nil) then
                return a["id"];
            else
                return client.web_client.im_open(user: userId)["channel"]["id"];
            end
        end

        def self.getChannelById(client, cId)
            return client.channels[cId];

            #begin
            #    return client.web_client.channels_info(channel: cId)["channel"];
            #rescue Slack::Web::Api::Error => err
            #    return nil;
            #end
        end

        ## Sometimes you don't want to answer stuff (help) in #general, so we shift it to private messages.
        ## Notify defines whether we should notify him about his pm in #general
        def self.replyByWhisper(client, data, msg, notify)
            if (Jaime::Util::getChannelById(client, data.channel) != nil) then # We are in a public channel
                client.say(channel: Jaime::Util::getIMChannelId(client, data.user), text: msg);
                if (notify) then
                    client.say(channel: data.channel, text: "<@#{data.user}>: I've PM'ed you with my response to not spam this channel. Next time consider messaging me directly with your commands :)");
                end
            else
                client.say(channel: data.channel, text: msg);
            end
        end

        def self.WhisperUser(client, userId, msg)
            if (userId != nil) then
                client.say(channel: Jaime::Util::getIMChannelId(client, userId), text: msg);
            else
                raise "Can't Whisper nil"
            end
        end

        def self.getJSONAPI(url)
            uri = URI(url);
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER # Should be the default

            response = http.request(Net::HTTP::Get.new(uri.request_uri)).body;
            return JSON.parse(response);
        end
    end
end