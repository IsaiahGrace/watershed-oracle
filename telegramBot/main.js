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
    // console.log(msg);
});

bot.on('location', (msg) => {
    const chatId = msg.chat.id;
    bot.sendMessage(chatId, 'Received your location, calculating your watershed!');
    proc.stdin.write(JSON.stringify({
        requestId: chatId,
        longitude: msg.location.longitude,
        latitude: msg.location.latitude,
    }));
    proc.stdin.write('\n');
    proc.stdin.flush();
});

const proc = Bun.spawn(["../zig-out/bin/watershedOracle",
    "--database=/home/isaiah/WBD_National_GPKG.gpkg",
    "--json"
], {
    stdin: "pipe",
    onExit(proc, exitCode, signalCode, error) {
        console.log("watershedOracle exited!");
        console.log(proc);
        console.log(exitCode);
        console.log(signalCode);
        console.log(error);
        process.exit(1);
    },
});

for await (let line of makeLineIterator(proc.stdout.getReader(), 1)) {
    const stack = JSON.parse(line);
    bot.sendMessage(stack.requestId, `Your point is in the following watersheds:
${stack.huc2  ? stack.huc2.name  : ""}
${stack.huc4  ? stack.huc4.name  : ""}
${stack.huc6  ? stack.huc6.name  : ""}
${stack.huc8  ? stack.huc8.name  : ""}
${stack.huc10 ? stack.huc10.name : ""}
${stack.huc12 ? stack.huc12.name : ""}
${stack.huc14 ? stack.huc14.name : ""}
${stack.huc16 ? stack.huc16.name : ""}`);
}
