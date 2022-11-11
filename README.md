meaningbot
==========

Meaning Bot is a Twitter bot that synthesizes aphorisms about life's meaning. Follow it at [@MeaningBot](https://twitter.com/meaningbot).

It uses [Chatterbot](https://github.com/muffinista/chatterbot), which is build on the [Twitter gem](https://github.com/sferik/twitter).

### Description

MeaningBot looks for tweets about the meaning (and point, and purpose…) of life, and combines pairs of them into aphorisms, which it then tweets. For example, it might combine these two tweets:

> The purpose of life is trying your hardest.

> Eating a meatball sub in the bathtub is the meaning of life.

into

> Eating a meatball sub in the bathtub is trying your hardest.

Care is taken to exclude words and phrases that result in boring content, and on each pass, we reference our past tweets in a effort not to be repetitive.

### Usage

The code for this bot lives in `meaning_bot.rb`, which contains the `MeaningBot` module, and also executes the `run` method defined therein. The bot can therefore be run both from the command line and from irb.

E.g. from the command line, you can run

> `$ ruby meaning_bot.rb 1 test`

which forces the script to build a tweet but runs the bot in test mode, outputting the tweet text instead of actually tweeting). Alternatively, 

> `$ ruby meaning_bot.rb 6`

would run in production mode, tweeting every 6th time on average. The reason to have the ability to throttle the tweet frequency is to provide some randomness in the tweeting cadence. In production, I run the script every 10 minutes and tweet 1 out of every 6 runs, resulting in a tweet per hour, on average..

To run the same two commands in Ruby, we would use the following:

> `MeaningBot.run(frequency: 1, testing: true)`

> `MeaningBot.run(frequency: 6)`
