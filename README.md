# Jamie, the Bot

There is not much to say about Jamie as he's currently pretty much WIP.  
He's a Slack Bot written in Ruby using the [slack-ruby-bot](https://github.com/dblock/slack-ruby-bot) framework.  

## Setup Process
For Security Reasons, we've gitignored the `.env` file.  
What's that? Well that's basically a file where we will load Settings to be set as Environment Variables during our code.  

Create it and add the Content `SLACK_API_TOKEN=your-token`.  
Also edit the settings in bot.rb:  
```
ADMIN_USERS = [ "U0P7BK890" ];
StartCapital = 1000
ABOUT=...
```

Please clearly state that you're not Jamie.  
The Bot will automatically listen to the Name you gave him during API TOKEN GENERATION, so you need to edit our Aliases found in `jaime.rb` (which is btw the main file)  

```ruby
SlackRubyBot.configure do |config|
    config.aliases = ['jaime', 'jamie?', 'jaime?']
end
```
Use this to catch up typos and the "?" and stuff.  

## Installation 
Clone this repo and run

``` cd /jamie/folder && ./jamie install ```

Note: Sometimes you receieve compilation errors due to missing C-Header Files on your System. Use Google for that.  

## Update and Auto update
For updating the bot with the latest sources run

``` cd /jamie/folder && ./jamie update ```

if there is an update available, it will be downloaded and the bot will restart.

If you want to make the bot autoupdate, you can add the command to the crontab.

Just run

```crontab -e```

and add at the end

```*/5 * * * * cd /jamie/folder && ./jamie update ```

this will try to update the bot every 5 minutes.

