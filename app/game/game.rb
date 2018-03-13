require_relative './board_contracts'


class Board 
    extend BoardContracts


    def initialize(diff) 
        @columns = 7
        @rows = 7 
        @board = Array.new(@rows){Array.new(@columns, 0)}
    end

    def add_piece(column_number)
        if can_add_to_column? column_number
            # add piece 
        end 
    end 



    private 

    def check_win 
        # return user that won 
    end 

    def clear_board 
        # return the board to empty state
    end



    # trivial public functions 
    public 

    def print_board
        # print board 
    end 

    def can_add_to_column?(column_number)
        # check column full
    end 

    def available_columns
        # list of columns that can have a piece added to it 
    end 

end 