# From the command line: 
#
#   $ ruby meaningbot.rb [FREQENCY] [TEST_MODE]
#
# E.g.
#
#   $ ruby meaning_bot.rb 1 test
#
# would run the bot in test mode, and force it to build a tweet, whereas
#
#   $ ruby meaning_bot.rb 6
#
# would run in production mode, tweeting every 6th time on average.
# To run the same two commands within Ruby:
#
#   > MeaningBot.run(frequency: 1, testing: true)
#   > MeaningBot.run(frequency: 6)
module MeaningBot
  require 'rubygems'
  require 'cgi'
  require 'chatterbot/dsl'

  module_function

  since_id 0

  # If provided, tweet one in every FREQUENCY times
  # the script is executed.
  FREQUENCY = ARGV[0] ? ARGV[0].to_i : nil

  # Don't perform public actions in test mode.
  TEST_MODE = ARGV[1] == 'test'

  # For use in the contenxt "the X of life"
  MEANING_NOUNS = %w{meaning purpose point}

  # These are our primary search terms.
  SUBJECT_QUERIES = MEANING_NOUNS.map{|n| " is the #{n} of life"}
  PREDICATE_QUERIES = MEANING_NOUNS.map{|n| "the #{n} of life is "}

  # Don't search for tweets including these.
  SEARCH_EXCLUSIONS = %q{-? -42 -Christ -"see the world" -bitch -cunt -Kanye -nigga -"getting shit done" -"Burger King" -"behind walls" -AskTamkin}

  # Don't tweet text that matches this.
  UNDESIRABLE_STRINGS = /http|@|#{MEANING_NOUNS.join('|')}/

  # Format search query in Twitter's search syntax.
  def search_term(queries, modifiers)
    [
      queries.map{|q| "\"#{q}\""}.join(' OR '),
      SEARCH_EXCLUSIONS,
      modifiers
    ].join(' ')
  end

  def one_nth_of_the_time(n)
    rand(n) == 0
  end

  # Perform a search and set Chatterbot's since_id back to zero,
  # so that future searches look as far back into history as possible.
  def get_search_tweets(query)
    tweets = client.search(query)

    since_id(0)

    tweets
  end

  # Search for "…is the meaning of life…" tweets.
  # Filter 'what' to avoid questions.
  def subject_tweets
    get_search_tweets search_term(SUBJECT_QUERIES, '-what')
  end

  # Search for "…the meaning of life is…" tweets.
  # Filter 'give' to avoid ubiquitous "to give life meaning" tweets.
  def predicate_tweets
    get_search_tweets search_term(PREDICATE_QUERIES, '-give')
  end

  # In lieu of persisting data, We grab our last 200 tweets
  # so that we can make an effort not to repeat ourselves.
  def recently_tweeted_text
    text = client.user_timeline(
      screen_name: 'meaningbot',
      count: 200,
      trim_user: true
    ).map(&:text).join.downcase

    since_id(0)

    CGI.unescapeHTML(text)
  end

  # Remove the common text (i.e meaning phrase) from a tweet.
  def strip_queries_from_tweet(tweet_text, queries, query_type)
    query_matchers = queries.map do |q|
      matcher = ''
      matcher += '.*' if query_type == :predicate
      matcher += q
      matcher += '.*' if query_type == :subject
      matcher
    end

    CGI.unescapeHTML(
      tweet_text.sub(/#{query_matchers.join('|')}/im, '').strip.gsub(/”|\"/, '')
    )
  end

  # Retrieve the two tweets that will be the raw material for the tweet.
  def pair_of_tweets
    recents = recently_tweeted_text

    # Search for tweets like "…is the meaning of life blah blah…",
    # and remove everything after and include "is the meaning of life".
    # Choose a random one that is short enough to go with the subject snippet
    # and isn't repetitive with old tweets
    subject_tweet = subject_tweets.map do |tweet|
      {
        tweet:,
        snippet: strip_queries_from_tweet(tweet.text, SUBJECT_QUERIES, :subject)
      }
    end.shuffle.find do |tweet|
      !(tweet[:snippet] =~ UNDESIRABLE_STRINGS) &&
        !(recents.index(tweet[:snippet].downcase))
    end

    # Search for tweets like "…the meaning of life is…",
    # and remove everything after and include "the meaning of life is".
    # Choose a random one that is short enough to go with the subject snippet,
    # doesn't include blacklisted words, and isn't repetitive with old tweets
    predicate_tweet = predicate_tweets.map do |tweet|
      {
        tweet:,
        snippet: strip_queries_from_tweet(tweet.text, PREDICATE_QUERIES, :predicate)
      }
    end.shuffle.find do |tweet|
      (tweet[:snippet].length + subject_tweet[:snippet].length + 4) < 280 &&
        !(tweet[:snippet] =~ UNDESIRABLE_STRINGS) &&
        !(recents.index(tweet[:snippet].downcase))
    end if subject_tweet

    [subject_tweet, predicate_tweet]
  end

  # Tweet an aphorism that combines subject and predicate tweet text,
  # and favorite the source tweets.
  # :frequency and :testing options are consulted if CLI args were not
  # provided.
  def run(opts={})
    frequency = FREQUENCY || opts[:frequency] || 6
    test_mode = TEST_MODE || opts[:testing]

    if one_nth_of_the_time(frequency)
      subject_tweet, predicate_tweet = pair_of_tweets

      if subject_tweet && predicate_tweet
        aphorism = subject_tweet[:snippet] + ' is ' + predicate_tweet[:snippet]

        puts "*" * 10
        if test_mode
          puts "TESTING MODE. NOT TWEETING."
        else
          puts "TWEETING!"
          tweet(aphorism)
          client.favorite(subject_tweet[:tweet])
          client.favorite(predicate_tweet[:tweet])
        end
        puts "SUBJECT FULL TEXT: " + subject_tweet[:tweet].text
        puts "PREDICATE FULL TEXT: " + predicate_tweet[:tweet].text
        puts "TWEET TEXT: " + aphorism
        puts "*"*10
      else
        puts "Not enough material."
      end
    else
      puts "Staying silent this time."
    end
  end

end

# Execute script.
MeaningBot.run
