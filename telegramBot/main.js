const TelegramBot = require('node-telegram-bot-api');
import makeLineIterator from './lineIterator.js';

// replace the value below with the Telegram token you receive from @BotFather
const token = 'REDACTED';

// Create a bot that uses 'polling' to fetch new updates
const bot = new TelegramBot(token, {
    polling: true
});

// Listen for any kind of message. There are different kinds of
// messages.
bot.on('message', (msg) => {
    // bot.sendMessage(chatId, 'Received your message');
});

bot.on('location', (msg) => {
    const chatId = msg.chat.id;

    // send a message to the chat acknowledging receipt of their message
    bot.sendMessage(chatId, 'Received your location, calculating your watershed!');

    //console.log("POINT(%f %f)", msg.location.longitude, msg.location.latitude);
    proc.stdin.write(`POINT(${msg.location.longitude} ${msg.location.latitude})\n`)
    gChatId = chatId;
});

const proc = Bun.spawn(["../zig-out/bin/watershedOracle",
    "--database=/home/isaiah/WBD_National_GPKG.gpkg"
], {
    stdin: "pipe",
    onExit(proc, exitCode, signalCode, error) {
        console.log("watershedOracle exited!");
        console.log(proc);
        console.log(exitCode);
        console.log(signalCode);
        console.log(error);
    },
});

let gChatId = null;

for await (let line of makeLineIterator(proc.stdout.getReader(), 8)) {
    bot.sendMessage(gChatId, line);
}
