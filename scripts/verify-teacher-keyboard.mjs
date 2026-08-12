const debuggingPort = process.env.CHROME_DEBUG_PORT ?? "9222";
const pageUrl = process.argv[2];
if (!pageUrl) throw new Error("Expected the teacher lifecycle page URL.");

const targetResponse = await fetch(
  `http://127.0.0.1:${debuggingPort}/json/new?${encodeURIComponent(pageUrl)}`,
  { method: "PUT" },
);
if (!targetResponse.ok) throw new Error(`Could not open Chrome target: ${targetResponse.status}`);
const target = await targetResponse.json();
const socket = new WebSocket(target.webSocketDebuggerUrl);
let sequence = 0;
const pending = new Map();

socket.addEventListener("message", (event) => {
  const message = JSON.parse(String(event.data));
  if (!message.id) return;
  const waiter = pending.get(message.id);
  if (!waiter) return;
  pending.delete(message.id);
  if (message.error) waiter.reject(new Error(JSON.stringify(message.error)));
  else waiter.resolve(message.result);
});
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

function send(method, params = {}) {
  const id = ++sequence;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

await send("Runtime.enable");
for (let attempt = 0; attempt < 40; attempt += 1) {
  const result = await send("Runtime.evaluate", {
    expression: "document.readyState",
    returnByValue: true,
  });
  if (result.result.value === "complete") break;
  await new Promise((resolve) => setTimeout(resolve, 100));
}
await send("Runtime.evaluate", { expression: "document.body.focus()" });

const expected = [
  "title",
  "start",
  "attendance",
  "transcript",
  "resource",
  "homework",
  "ai",
  "review",
  "publish",
];
const observed = [];
for (const expectedKey of expected) {
  await send("Input.dispatchKeyEvent", {
    type: "keyDown",
    key: "Tab",
    code: "Tab",
    windowsVirtualKeyCode: 9,
  });
  await send("Input.dispatchKeyEvent", {
    type: "keyUp",
    key: "Tab",
    code: "Tab",
    windowsVirtualKeyCode: 9,
  });
  const result = await send("Runtime.evaluate", {
    expression: "document.activeElement?.dataset?.keyboardOrder ?? ''",
    returnByValue: true,
  });
  observed.push(result.result.value);
  if (result.result.value !== expectedKey) {
    throw new Error(
      `Keyboard order mismatch: expected ${expectedKey}, got ${result.result.value || "<none>"}. Sequence: ${observed.join(", ")}`,
    );
  }
}

console.log(`Keyboard order verified: ${observed.join(" -> ")}`);
socket.close();
