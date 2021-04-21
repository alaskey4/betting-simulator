require 'pg'

class Simulator

    attr_accessor :balance, :consecutive_losses, :consecutive_wins, :count, :num_losses, :num_wins, :wager
    attr_reader :base_wager, :loss_log, :win_log

    def initialize(num_bets, base_wager)      
        @balance = 100000000                #balance can be any number the user wants
        @base_wager = base_wager
        @consecutive_losses = 0
        @consecutive_wins = 0
        @count = num_bets                   #count represents how many bets remain in the simulation, so the num_bets will never change
        @loss_log = []                      #logs consecutive loss streaks
        @num_losses = 0
        @num_wins = 0               
        @wager = base_wager                 #the wager will change frequently, but the base_wager should never change 
        @win_log = []                       #logs consecutive win streaks
        play                                #automatically begin simulated betting round 
    end

    def play
        original_balance = self.balance                             #original and final balance will be used at the end to determine profit margin
        place_bet until self.count == 0 || self.balance <= 0        #betting continues until the count reaches 0 or the user runs out of funds        
        final_balance = self.balance
        results(original_balance, final_balance)    
    end

    def place_bet
        num = rand(1..10000)                        #randomly generate a number between 1 and 10000
        self.count -= 1            
        outcome(num)                                
    end

    def outcome(num)
        if num.even?                                #even numbers result in a win
            self.balance += self.wager              #a win increases the balance by the amount of the wager (assumes +100% return)
            puts "WIN #{self.count}"               
            self.wager = self.base_wager            #the wager increases after each loss and resets after a win
            loss_log << self.consecutive_losses     #loss_log logs the number of consecutive losses before a win
            self.consecutive_losses = 0             #on a win, consecutive_losses resets
            self.consecutive_wins += 1              
            self.num_wins += 1
        else                                        #odd numbers result in a loss
            self.balance -= self.wager              #a loss decreases the balance by the amount of the wager
            puts "LOSE #{self.count}"
            win_log << self.consecutive_wins        #win_log logs the number of consecutive wins before a loss
            self.consecutive_losses += 1            
            self.consecutive_wins = 0               #on a loss, consecutive_wins resets
            self.wager *= 3                         #after a loss, the wager is tripled - as long as the balance can cover, each loss provides the opportunity for a greater win next time
            self.count += 1 if self.count == 0      #allows for an additional bet if the final bet results in a loss - simulation can only end on a winning bet
            self.num_losses += 1         
        end
    end

    private

    def results(original_balance, final_balance)
        profit = final_balance - original_balance
        win_percentage = 100.0 * self.num_wins / (self.num_wins + self.num_losses)
        stats = {
            "balance" => final_balance,
            "profit" => profit,
            "wins" => self.num_wins, 
            "losses" => self.num_losses,
            "win percentage" => win_percentage,
            "max win streak" => win_log.max,
            "max loss streak" => loss_log.max
        }
        puts stats
        upload(profit, win_percentage)
    end

    def upload(profit, win_percentage)
        begin
            con = PG.connect :dbname => 'results', :user => 'alaskey'                                                                           #connects to db
            con.exec "INSERT INTO stats (base_wager, win_percentage, profit) VALUES (#{self.base_wager}, #{win_percentage}, #{profit})"         #inserts new row of data
            #data = con.exec "SELECT * FROM stats"
            #puts
            #data.each { |row| puts "%s %s %s %s" % [ row['id'], row['base_wager'], row['win_percentage'], row['profit'] ] }                    #prints the results of the table
        rescue PG::Error => e                                                                                                                   #checks for errors
            puts e.message
        ensure
            con.close if con                                                                                                                    #releases the info
        end
    end

end

Simulator.new(10000, 1)