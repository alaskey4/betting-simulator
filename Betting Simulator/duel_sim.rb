require 'pg'

class Duel

    attr_accessor :bal_1, :bal_2, :count, :wager_1, :wager_2, :consecutive_losses_1, :consecutive_losses_2
    attr_reader :base_wager_1, :base_wager_2

    def initialize(num_bets, base_wager_1, base_wager_2)
        @bal_1 = 100000000
        @bal_2 = 100000000
        @count = num_bets
        @base_wager_1 = base_wager_1 
        @base_wager_2 = base_wager_2
        @wager_1 = base_wager_1
        @wager_2 = base_wager_2
        @consecutive_losses_1 = 0
        @consecutive_losses_2 = 0
        play 
    end

    def play
        original_balances = [self.bal_1, self.bal_2]
        place_bets until self.count == 0
        final_balances = [self.bal_1, self.bal_2]
        results(original_balances, final_balances)    
    end

    def place_bets
        num = rand(1..10000)
        self.count -= 1
        puts outcomes(num)
        self.count += 1 if self.count == 0 && outcomes(num).include?("L")
    end

    def outcomes(num)
        "#{outcome_1(num)} #{outcome_2(num)} #{self.count}"
    end

    def outcome_1(num)
        if num.even?
            self.bal_1 += self.wager_1
            self.wager_1 = self.base_wager_1    
            self.consecutive_losses_1 = 0
            return "WIN"
        else
            self.bal_1 -= self.wager_1
            self.consecutive_losses_1 += 1
            self.wager_1 *= 3 
            return "LOSE"
        end
    end

    def outcome_2(num)
        if num > 5000
            self.bal_2 += self.wager_2
            self.wager_2 = self.base_wager_2      
            self.consecutive_losses_2 = 0
            return "WIN"
        else
            self.bal_2 -= self.wager_2
            self.consecutive_losses_2 += 1
            self.wager_2 *= 3
            return "LOSE"
        end
    end

    private

    def results(original_balances, final_balances)
        profit_1 = final_balances.first - original_balances.first
        profit_2 = final_balances.last - original_balances.last
        if profit_1 > profit_2
            winner = 1
        elsif profit_2 > profit_1
            winner = 2
        else
            winner = 0
        end
        stats = {
            "profit_1" => "#{profit_1}",
            "profit_2" => "#{profit_2}",
            "winner" => winner
        }
        puts stats
        upload(profit_1, profit_2, winner)
    end

    def upload(profit_1, profit_2, winner)
        begin
            con = PG.connect :dbname => 'results', :user => 'alaskey'
            con.exec "INSERT INTO duels (profit_1, profit_2, winner) VALUES (#{profit_1}, #{profit_2}, #{winner})"
        rescue PG::Error => e
            puts e.message
        ensure
            con.close if con
        end
    end

end

Duel.new(10000, 1, 1)