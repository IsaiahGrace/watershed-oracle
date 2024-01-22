module.exports = makeLineIterator;

// I did not write this code. I found it online somewhere and now I can't find it again to attribute it correctly.
// This is the kind of thing I'd really like to see in a language's standard library...

async function* makeLineIterator(reader, lineGroupSize) {
    const utf8Decoder = new TextDecoder("utf-8");
    let {
        value: chunk,
        done: readerDone
    } = await reader.read();
    chunk = chunk ? utf8Decoder.decode(chunk, {
        stream: true
    }) : "";

    let re = /\r\n|\n|\r/gm;
    let startIndex = 0;
    let linesRead = 0;

    for (;;) {
        let result = re.exec(chunk);
        if (!result) {
            if (readerDone) {
                break;
            }
            let remainder = chunk.substr(startIndex);
            ({
                value: chunk,
                done: readerDone
            } = await reader.read());
            chunk =
                remainder + (chunk ? utf8Decoder.decode(chunk, {
                    stream: true
                }) : "");
            startIndex = re.lastIndex = 0;
            continue;
        }
        linesRead++;
        if (linesRead >= lineGroupSize) {
            yield chunk.substring(startIndex, result.index);
            startIndex = re.lastIndex;
            linesRead = 0;
        }
    }

    if (startIndex < chunk.length) {
        // last line didn't end in a newline char
        yield chunk.substr(startIndex);
    }
}
