require_relative './game_contracts'
require_relative './game_error'

require_relative '../board/board'
require_relative '../player/player'
require_relative '../player/ai'


class Game 
    include GameContracts
    attr_reader :players, :board, :current_player_num

    def initialize(rows=nil, columns=nil, players=nil, debug=false)
        pre_init(rows, columns, players)

        @observers = []
        @debug = debug
        set_game_dimensions(rows, columns)
        set_game_players(players)

        post_init
        invariant
    end

    def print_state 
        curr_player = @players[@current_player_num]
        @players.each { |p| 
            if p == curr_player
                puts "The current player: " + p.to_s
            end 
        }

        puts @board.print_board
    end 


    def get_current_player
        invariant 
        pre_get_current_player
        
        player = @players[@current_player_num]
        
        post_get_current_player
        invariant 

        player
    end

    def reset_current_player(player)
        index = @players.rindex(player)

        @current_player_num = index
    end 

    def play_move(column=nil,token=nil)
        invariant 
        pre_play_move(column)
        beforeboard = @board.dup

        current_player = @players[@current_player_num]
        if current_player.is_a? AIOpponent
            column = current_player.choose_column(@board, @players, @current_player_num, token)
        end

        token = current_player.tokens.sample if token.nil? 

        begin
            row = @board.add_piece(column, token)
        rescue *GameError.TryAgain => slip
            if slip.is_a? NotAValidColumn
                slip.column ? (puts "Column number: " + slip.column + " is not valid.") : (puts "Column number is not valid.")
            end 
            reset_current_player(current_player)
            puts current_player.player_name + " please try your move again."
            @observers.each{|o| o.show_error(current_player.player_name + " please try your move again.")}
            return
        end

        @observers.each{|o| o.update_token(column,row,token)}

        begin 
            check_game(current_player)
        rescue *GameError.GameEnd => game_end
            if game_end.is_a? GameWon
                puts "Congratulations, we have a winner"
                puts game_end.player.player_name + " won with the combination: " + game_end.player.player_win_condition.to_s
                @observers.each{|o| o.show_winner(game_end.player.player_name + " won!")}
            else
                puts "There are no more possible moves. It's a cats game!"
                @observers.each{|o| o.show_winner("No winner")}
            end
            return
        rescue *GameError.TryAgain => slip
            if slip.is_a? NotAValidColumn
                slip.column ? (puts "Column number: " + slip.column + " is not valid.") : (puts "Column number is not valid.")
            end 
            reset_current_player(current_player)
            puts current_player.player_name + " please try your move again."
            @observers.each{|o| o.show_error(current_player.player_name + " please try your move again.")}
            return
        rescue *GameError.Wrong => error 
            puts "Something went wrong sorry"
            puts error.message
            @observers.each{|o| o.show_error(error.message,true)}
            return
        end   

        debug_print if @debug

        increment_player        

        post_play_move(beforeboard)
        invariant 

        return row
    end

    def add_observer(view)
        @observers << view
    end

    private

    def debug_print
        puts "----------------"
        puts @players[@current_player_num].player_name + "'s turn"
        puts @board.print_board
        puts "----------------"
    end

    def check_game(current_player)
        invariant
        pre_check_game

        combinations = @board.get_all_combinations_of_length(current_player.player_win_condition.length)
        @players.each { |p|
            if combinations.include? p.player_win_condition
                raise GameWon.new(p)
            elsif @board.is_full?
                raise NoMoreMoves.new
            end
        }

        post_check_game
        invariant
    end

    def increment_player
        invariant 
        old_num = pre_increment_player

        @current_player_num += 1 
        if @current_player_num >= @players.size
            @current_player_num = 0
        end

        if !(@players[@current_player_num].is_a? AIOpponent)
            @observers.each{|o| o.update_buttons(@players[@current_player_num].tokens[0], @players[@current_player_num].player_name)}
        end

        post_increment_player(old_num)
        invariant 
    end

    def set_game_dimensions(rows, columns)
        invariant 
        pre_set_game_dimensions

        if rows.nil? && columns.nil?
            @board = Board.new(6,7)
        else 
            @board = Board.new(rows,columns)
        end

        post_set_game_dimensions 
        invariant 
    end

    def set_game_players(players)
        invariant 
        pre_set_game_players

        @players = players
        if players.nil? 
            p1 = Player.new("Player1", ["R", "R", "R", "R"]) 
            p2 = AIOpponent.new("Player2", ["Y", "Y", "Y", "Y"], 3)
            @players = [p1, p2]
        end

        @current_player_num = 0

        post_set_game_players 
        invariant 
    end

end 
