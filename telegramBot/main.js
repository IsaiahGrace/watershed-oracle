const TelegramBot = require('node-telegram-bot-api');
import makeLineIterator from './lineIterator.js';

// The process.env Bun feature reads key-value pairs from several potential .env files.
// See https://bun.sh/docs/runtime/env for details.
// These are variables I do not want to include in a public git repo.
const {
    DATABASE_PATH,  // The full path ('~' not allowed) to the WBD_National_GPKG.gpkg database file.
    DEBUG_CHAT_ID,  // A Telegram chat ID to send debug messages (optional).
    SECRET_TOKEN    // The Telegram bot API token given by @BotFather during bot creation.
} = process.env;

// Create a bot that uses 'polling' to fetch new updates
const bot = new TelegramBot(SECRET_TOKEN, {
    polling: true
});

// Callback for all types of messages.
bot.on('message', (msg) => {
    // console.log(msg);
});

// Callback for messages with the 'location' feature.
bot.on('location', (msg) => {
    bot.sendMessage(DEBUG_CHAT_ID, "location request received");

    // Putting the write call to the Zig program in the callback ensures that the acknowledgement
    // message is delivered to the user first. The Zig lookup is so fast, that sometimes the
    // resulting watershed data would appear before the ack msg.
    bot.sendMessage(msg.chat.id, "Received your location, calculating your watershed!").then(() => {
        proc.stdin.write(JSON.stringify({
            requestId: msg.chat.id,
            longitude: msg.location.longitude,
            latitude: msg.location.latitude,
        }));
        proc.stdin.write('\n');
        proc.stdin.flush();
    });
});

const proc = Bun.spawn(["../zig-out/bin/watershedOracle",
    `--database=${DATABASE_PATH}`,
    "--json"
], {
    stdin: "pipe",
    onExit(proc, exitCode, signalCode, error) {
        const promise = bot.sendMessage(DEBUG_CHAT_ID, "watershedOracle zig process exited");
        console.log("watershedOracle exited!");
        console.log("proc:");
        console.log(proc);
        console.log("exitCode:");
        console.log(exitCode);
        console.log("signalCode:");
        console.log(signalCode);
        console.log("error:");
        console.log(error);
        promise.then(() => {process.exit(1);});
    },
});


bot.sendMessage(DEBUG_CHAT_ID, "Telegram Bot Bun server online.");

for await (let line of makeLineIterator(proc.stdout.getReader(), 1)) {
    const stack = JSON.parse(line);
    bot.sendMessage(stack.requestId, `Your point is in the following watersheds:
\`\`\`
${stack.huc2  ? "Level  2: " + stack.huc2.name  : ""}
${stack.huc4  ? "Level  4: " + stack.huc4.name  : ""}
${stack.huc6  ? "Level  6: " + stack.huc6.name  : ""}
${stack.huc8  ? "Level  8: " + stack.huc8.name  : ""}
${stack.huc10 ? "Level 10: " + stack.huc10.name : ""}
${stack.huc12 ? "Level 12: " + stack.huc12.name : ""}
${stack.huc14 ? "Level 14: " + stack.huc14.name : ""}
${stack.huc16 ? "Level 16: " + stack.huc16.name : ""}
\`\`\``,
    {parse_mode: "MarkdownV2"});
}
