@'
const { WebSocketServer } = require('ws');

const PORT = 8080;
const wss = new WebSocketServer({ port: PORT, host: '0.0.0.0' });

const history = [];

wss.on('connection', (socket) => {
    console.log('Client connected. Total:', wss.clients.size);

    socket.send(JSON.stringify({ type: 'history', messages: history }));

    socket.on('message', (raw) => {
        let msg;
        try {
            msg = JSON.parse(raw.toString());
        } catch (e) {
            return;
        }
        if (!msg.text || !msg.sender || !msg.groupId) return;

        const saved = {
            sender: msg.sender,
            groupId: msg.groupId,
            text: msg.text,
            time: new Date().toISOString(),
        };
        history.push(saved);

        const out = JSON.stringify({ type: 'message', message: saved });
        for (const client of wss.clients) {
            if (client.readyState === 1) client.send(out);
        }
    });

    socket.on('close', () => {
        console.log('Client left. Total:', wss.clients.size);
    });
});

console.log('Chat server running on port', PORT);
'@ 
    | Set - Content - Encoding utf8 server.js