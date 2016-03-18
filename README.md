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

```
SlackRubyBot.configure do |config|
    config.aliases = ['jaime', 'jamie?', 'jaime?']
end
```
Use this to catch up typos and the "?" and stuff.  