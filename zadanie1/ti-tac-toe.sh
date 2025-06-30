#!/bin/bash

SAVE_FILE="ttt_save.dat"
BOARD=(. . . . . . . . .)
PLAYER="X"
MODE=""

draw_board() {
    echo
n=0
    for i in {0..2}; do
        echo " ${BOARD[n]} | ${BOARD[n+1]} | ${BOARD[n+2]}"
        [[ $i -lt 2 ]] && echo "---+---+---"
        ((n+=3))
    done
    echo
}

check_win() {
    local b=(${BOARD[@]})
    local lines=("0 1 2" "3 4 5" "6 7 8" "0 3 6" "1 4 7" "2 5 8" "0 4 8" "2 4 6")
    for line in "${lines[@]}"; do
        set -- $line
        if [[ "${b[$1]}" != "." && "${b[$1]}" == "${b[$2]}" && "${b[$2]}" == "${b[$3]}" ]]; then
            echo "win:$PLAYER"
            return
        fi
    done
    for cell in "${b[@]}"; do
        [[ "$cell" == "." ]] && return
    done
    echo "draw"
}

save_game() {
    printf "%s\n" "$MODE" "$PLAYER" "${BOARD[*]}" > "$SAVE_FILE"
    echo "Game saved to $SAVE_FILE"
}

load_game() {
    if [[ ! -f $SAVE_FILE ]]; then
        echo "No save file found."
        return 1
    fi
    read -r MODE < <(sed -n '1p' "$SAVE_FILE")
    read -r PLAYER < <(sed -n '2p' "$SAVE_FILE")
    read -r -a BOARD < <(sed -n '3p' "$SAVE_FILE")
    echo "Game loaded from $SAVE_FILE"
}

player_move() {
    local cell
    while true; do
        read -p "Player $PLAYER, enter cell (1-9) or 'save': " cell
        if [[ "$cell" == "save" ]]; then
            save_game
            continue
        fi
        if [[ ! $cell =~ ^[1-9]$ ]]; then
            echo "Invalid input. Choose 1-9."
            continue
        fi
        ((cell--))
        if [[ "${BOARD[cell]}" != "." ]]; then
            echo "Cell occupied."
        else
            BOARD[cell]="$PLAYER"
            break
        fi
    done
}

computer_move() {
    echo "Computer ($PLAYER) is thinking..."
    sleep 1
    local empties=()
    for i in {0..8}; do
        [[ "${BOARD[i]}" == "." ]] && empties+=("$i")
    done
    local choice=${empties[RANDOM % ${#empties[@]}]}
    BOARD[$choice]="$PLAYER"
    echo "Computer placed at $((choice+1))"
}

switch_player() {
    [[ "$PLAYER" == "X" ]] && PLAYER="O" || PLAYER="X"
}

main_loop() {
    while true; do
        draw_board
        if [[ "$MODE" == "1" && "$PLAYER" == "O" ]]; then
            computer_move
        else
            player_move
        fi
        result=$(check_win)
        if [[ "$result" == win:* ]]; then
            draw_board
            winner=${result#win:}
            echo "Player $winner wins!"
            break
        elif [[ "$result" == "draw" ]]; then
            draw_board
            echo "It's a draw!"
            break
        fi
        switch_player
    done
}

echo "Tic-Tac-Toe Bash"
PS3="Select option: "
options=("New: Human vs Human" "New: Human vs Computer" "Load game" "Quit")
select opt in "${options[@]}"; do
    case \$REPLY in
        1) MODE=0; break;;
        2) MODE=1; break;;
        3) load_game && break;;
        4) exit 0;;
        *) echo "Invalid option.";;
    esac
    opt=""
done
main_loop
