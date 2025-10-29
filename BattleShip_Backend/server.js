const WebSocket = require('ws');
const server = new WebSocket.Server({ port: 8080 });
const express = require('express');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid'); 
const cors = require('cors');
const fs = require('fs');
const https = require('https');

const app = express();
const PORT = 3000;

const availableColors = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange"];

app.use(bodyParser.json());
app.use(cors());

const rooms = new Map();
const users = new Map();
const playerConnections = new Map(); 
const websocketUrl = `wss://localhost:3000`; 

const serverOptions = {
    key: fs.readFileSync('./localhost.key'),
    cert: fs.readFileSync('./localhost.crt'),
};

app.server = https.createServer(serverOptions, app);

const wss = new WebSocket.Server({ server: app.server });

let timer;
const timerDuration = 30000; // 30 seconds

wss.on("connection", (ws, req) => {
    const user_id = req.url.split("=")[1]; 

    playerConnections.set(user_id, ws);

    ws.on("message", (message) => {
        const data = JSON.parse(message);

        if (data.operation === 1) {
            handleStartGame(ws, data);
        }
        else if (data.operation === 2) {
            handleRound0(ws, data);
        }
        else if (data.operation === 4) {
            handleRound1(ws, data);
        }
    });

    ws.on("close", () => {
        handlePlayerDisconnection(user_id)
        playerConnections.delete(user_id);
    });
});

  app.server.listen(PORT, () => {
    console.log(`Server is running on https://localhost:${PORT}`);
  });

function startTimer(userId) {
    if (timer) {
        clearTimeout(timer);
    }

    timer = setTimeout(() => {
        onTimerEnd(userId);
    }, timerDuration);
}

function onTimerEnd(userId) {
    console.log('Timer has ended for user: ' + userId);

    handlePlayerDisconnection(userId)
    playerConnections.delete(userId);
}

app.post('/join-room', (req, res) => {
    const { room_id } = req.body;

    if (!room_id) {
        return res.status(400).json({
            message: 'Missing parameter room_id',
            error_code: 2002,
        });
    }

    if (!rooms.get(room_id)) {
        return res.status(400).json({
            message: 'Invalid room ID',
            error_code: 2001,
        });
    }

    const room = rooms.get(room_id);

    if (room.players.length >= room.maxPlayers) {
        return res.status(400).json({
            message: 'The room is alredy full',
            error_code: 2003,
        });
    }

    if (room.round >= 0) {
        return res.status(400).json({
            message: 'The game in the room are alredy started',
            error_code: 2004,
        });
    }

    const user_id = uuidv4().replace(/-/g, '').substring(0, 6);

    room.players.push(user_id);
    users.set(user_id, room_id)

    room.players.forEach((playerId) => {
        const ws = playerConnections.get(playerId);
        if (ws) {
            ws.send(
                JSON.stringify({
                    operation: 0,
                    number_of_current_players: room.players.length,
                })
            );
        }
    });

    res.status(200).json({
        user_id: user_id,
        room_id: room_id,
        websocket_url: websocketUrl+"/?userId="+user_id,
        number_of_players: room.maxPlayers,
        number_of_current_players: room.players.length,
    });
});

app.post('/create-room', (req, res) => {
    console.log("create room")
    const { number_of_players } = req.body;

    if (!Number.isInteger(number_of_players)) {
        return res.status(400).json({
            error_code: 1002,
            message: 'Missing parameter number_of_players',
        });
    }
    if (number_of_players <= 1) {
        return res.status(400).json({
            error_code: 1001,
            message: 'The number of players need to be 2 or more',
        });
    }

    const userId = uuidv4().replace(/-/g, '').substring(0, 6); 
    const roomId = uuidv4().replace(/-/g, '').substring(0, 6); 

    rooms.set(roomId, {
        owner: userId,
        players: [userId],
        maxPlayers: number_of_players,
        round: -1
    });

    users.set(userId, roomId)

    return res.status(200).json({
        user_id: userId,
        room_id: roomId,
        websocket_url: websocketUrl+"/?userId="+userId,
    });
});

function handlePlayerDisconnection(userId) {
    const roomId = users.get(userId)
    const room = rooms.get(roomId)

    if (room.round < 0) {
        room.players = removeElement(room.players, userId)
        room.players.forEach((playerId) => {
            const ws = playerConnections.get(playerId);
            if (ws) {
                ws.send(
                    JSON.stringify({
                        operation: 0,
                        number_of_current_players: room.players.length,
                    })
                );
            }
        });
        return
    }
    else if (room.round == 0) {
        room["players_tables"][user_id] = null
        room["players_ready_user_id"] = removeElement(room["players_ready_user_id"], userId)
        room["players_ready_color"] = removeElement(room["players_ready_color"], room["players_colors"][user_id])
        room.players.forEach((playerId) => {
            const ws = playerConnections.get(playerId);
            if (ws) {
                ws.send(
                    JSON.stringify({
                        operation: 2,
                        round: room["round"],
                        completed_round0_players: room["players_ready_color"]
                    })
                );
            }
        });
        return 
    }

    const current_turn = room["players_order"][room["current_order"]]

    if (room.players_order.indexOf(current_turn) > room.players_order.indexOf(room.players_colors[userId])) {
        room.current_order = room.current_order -2
        nextTurn(room)
    }
    room.players_order = removeElement(room.players_order, current_turn)

    if (room.players_order.length == 1) {
        room.players.forEach((playerId) => {
            const ws = playerConnections.get(playerId);
            if (ws) {
                ws.send(
                    JSON.stringify({
                        operation: 5,
                        winner: room.players_order[0],
                    })
                );
            }
        });
    }
    else {
        room.players.forEach((playerId) => {
            const ws = playerConnections.get(playerId);
            if (ws) {
                ws.send(
                    JSON.stringify({
                        operation: 6,
                        round: room["round"],
                        current_player_turn: room["players_order"][room["current_order"]],
                        players_order: room["players_order"]
                    })
                );
            }
        });
    }
}


function handleStartGame(ws, data) {
    const { operation, user_id, room_id } = data;
    if (!rooms.has(room_id)) {
        return ws.send(
            JSON.stringify({
                message: "Invalid room_id",
                error_code: 3002,
            })
        );
    }

    const room = rooms.get(room_id);
    if (room.owner != user_id) {
        return ws.send(
            JSON.stringify({
                message: "The game can only be started by the creator of the room",
                error_code: 3003,
            })
        );
    }

    if (room.round != -1) {
        return ws.send(
            JSON.stringify({
                message: "The game in the room are alredy started",
                error_code: 3004,
            })
        );
    }

    if (room.players.length < 2) {
        return ws.send(
            JSON.stringify({
                message: "The number of players in the room need to be at least 2",
                error_code: 3001,
            })
        );
    }

    const playerColors = {};
    const intern_colors_by_user_id = {};
    room.players.forEach((playerId, index) => {
        playerColors[playerId] = availableColors[index % availableColors.length];
        intern_colors_by_user_id[playerColors[playerId]] = playerId
    });

    room["round"] = 0
    room["players_ready_user_id"] = []
    room["players_ready_color"] = []
    room["players_colors"] = playerColors
    room["intern_colors_by_user_id"] = intern_colors_by_user_id
    room["players_tables"] = new Map()

    room.players.forEach((playerId) => {
        const ws = playerConnections.get(playerId);
        if (ws) {
            ws.send(
                JSON.stringify({
                    operation: 1,
                    round: room["round"],
                    user_color: room["players_colors"][playerId],
                })
            );
        }
    });
}

function handleRound0(ws, data) {
    const { operation, user_id, room_id, player_table } = data;
    if (!user_id || !room_id) {
        return ws.send(
            JSON.stringify({
                message: "Missing parameters",
                error_code: 4003,
            })
        );
    }

    if (!rooms.has(room_id)) {
        return ws.send(
            JSON.stringify({
                message: "Invalid room_id",
                error_code: 4002,
            })
        );
    }

    const room = rooms.get(room_id);
    if (room.round != 0) {
        return ws.send(
            JSON.stringify({
                message: "The round 0 has already ended or not started yet",
                error_code: 4004,
            })
        );
    }

    if (!room.players.includes(user_id)) {
        return ws.send(
            JSON.stringify({
                message: "Invalid user_id",
                error_code: 4005,
            })
        );
    }

    if (room.players_ready_user_id.includes(user_id)) {
        return ws.send(
            JSON.stringify({
                message: "The user has alredy played his round 0",
                error_code: 4006,
            })
        );
    }

    if (!checkTableCorrectness(player_table)) {
        return ws.send(
            JSON.stringify({
                Message: "Invalid table format",
                Error_code: 4001,
            })
        );
    }

    room["players_tables"][user_id] = player_table
    room["players_ready_user_id"].push(user_id)
    room["players_ready_color"].push(room["players_colors"][user_id])

    room.players.forEach((playerId) => {
        const ws = playerConnections.get(playerId);
        if (ws) {
            ws.send(
                JSON.stringify({
                    operation: 2,
                    round: room["round"],
                    completed_round0_players: room["players_ready_color"]
                })
            );
        }
    });

    if (room.players_ready_user_id.length == room.players.length) {
        room["players_order"] = Object.values(room.players_colors)
        room["current_order"] = 0
        room["round"] = 1
        startTimer(room["intern_colors_by_user_id"][room["players_order"][room["current_order"]]])
        room.players.forEach((playerId) => {
            const ws = playerConnections.get(playerId);
            if (ws) {
                ws.send(
                    JSON.stringify({
                        operation: 3,
                        round: room["round"],
                        players_order: room["players_order"],
                        current_player_turn: room["players_order"][room["current_order"]],
                    })
                );
            }
        });
    }
}

function handleRound1(ws, data) {
    const { operation, user_id, room_id, player_color, coordinates } = data;

    if (coordinates.x < 0 || coordinates.y < 0 || coordinates.x > 9 || coordinates.y > 9) {
        return ws.send(
            JSON.stringify({
                message: "Invalid coordinates",
                error_code: 5001,
            })
        );
    }

    if (!user_id || !room_id) {
        return ws.send(
            JSON.stringify({
                message: "Missing parameters",
                error_code: 5003,
            })
        );
    }

    if (!rooms.has(room_id)) {
        return ws.send(
            JSON.stringify({
                message: "Invalid room_id",
                error_code: 5002,
            })
        );
    }

    const room = rooms.get(room_id);

    if (room.round < 1) {
        return ws.send(
            JSON.stringify({
                Message: `The game current round is 0 or below`,
                Error_code: 5004,
            })
        );
    }

    if (!room.players.includes(user_id)) {
        return ws.send(
            JSON.stringify({
                Message: "Invalid user_id ",
                Error_code: 5008,
            })
        );
    }

    const current_turn = room["players_order"][room["current_order"]]

    if (current_turn != room.players_colors[user_id]) {
        return ws.send(
            JSON.stringify({
                Message: "Is the turn of another player",
                Error_code: 5007,
            })
        );
    }

    const attacked_user_id = room.intern_colors_by_user_id[player_color]

    if (!attacked_user_id || !room.players_order.includes(player_color) || attacked_user_id == user_id) {
        return ws.send(
            JSON.stringify({
                Message: "The attacked player is not valid",
                Error_code: 5005,
            })
        );
    }

    const cell_value = room.players_tables[attacked_user_id][coordinates.x][coordinates.y]

    if (cell_value < 0) {
        return ws.send(
            JSON.stringify({
                Message: "Some player already attacked that cell of the player",
                Error_code: 5006,
            })
        );
    }
    else if (cell_value == 0) {
        room.players_tables[attacked_user_id][coordinates.x][coordinates.y] = -1
        nextTurn(room)
        startTimer(room["intern_colors_by_user_id"][room["players_order"][room["current_order"]]])
        room.players.forEach((playerId) => {
            const ws = playerConnections.get(playerId);
            if (ws) {
                ws.send(
                    JSON.stringify({
                        operation: 4,
                        attack_emisor_color: current_turn,
                        attack_receptor_color: player_color,
                        coordinates: coordinates,
                        result: -1,
                        round: room["round"],
                        current_player_turn: room["players_order"][room["current_order"]],
                        players_order: room["players_order"],
                    })
                );
            }
        });
    }
    else {
        if (room.players_tables[attacked_user_id]) {
            room.players_tables[attacked_user_id][coordinates.x][coordinates.y] = -cell_value
            nextTurn(room)
            startTimer(room["intern_colors_by_user_id"][room["players_order"][room["current_order"]]])
            if (checkIfPlayerDie(room.players_tables[attacked_user_id])) {
                room.players_order = removeElement(room.players_order, player_color)
            }

            if (room.players_order.length == 1) {
                room.players.forEach((playerId) => {
                    const ws = playerConnections.get(playerId);
                    if (ws) {
                        ws.send(
                            JSON.stringify({
                                operation: 4,
                                attack_emisor_color: current_turn,
                                attack_receptor_color: player_color,
                                coordinates: coordinates,
                                result: -2,
                            })
                        );

                        ws.send(
                            JSON.stringify({
                                operation: 5,
                                winner: room.players_order[0],
                            })
                        );
                    }
                });
            }
            else {
                room.players.forEach((playerId) => {
                    const ws = playerConnections.get(playerId);
                    if (ws) {
                        ws.send(
                            JSON.stringify({
                                operation: 4,
                                attack_emisor_color: current_turn,
                                attack_receptor_color: player_color,
                                coordinates: coordinates,
                                result: -2,
                                round: room["round"],
                                current_player_turn: room["players_order"][room["current_order"]],
                                players_order: room["players_order"]
                            })
                        );
                    }
                });
            }
        }
                
    }
}

function checkTableCorrectness(table) {
    
    return true
}

function nextTurn(room) {
    console.log(room)
    var current_order = room.current_order
    if (current_order == (room.players_order.length - 1)) {
        current_order = 0
        room.round = room.round + 1
    }
    else {
        current_order = current_order + 1
    }
    room.current_order = current_order
    console.log(room)

}

function checkIfPlayerDie(table) {
    return table.every(row => row.every(value => value < 1));
}

function removeElement(array, element) {
    return array.filter(el => el !== element);
}
