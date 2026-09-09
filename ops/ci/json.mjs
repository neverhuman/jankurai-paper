// Strict JSON object parsing shared by CI inputs and artifact validation.
export function parseUniqueJson(text) {
  const value = JSON.parse(text);
  // JSON.parse accepts repeated keys. Reject ambiguous objects before validation.
  const tokens = text.match(/"(?:\\[\s\S]|[^"\\])*"|[{}\[\],:]/g) ?? [];
  const stack = [];
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (token === '{') stack.push(new Set());
    else if (token === '[') stack.push(null);
    else if (token === '}' || token === ']') stack.pop();
    else if (token.startsWith('"') && tokens[i + 1] === ':') {
      const key = JSON.parse(token);
      if (stack.at(-1).has(key)) throw new Error(`duplicate JSON key: ${key}`);
      stack.at(-1).add(key);
    }
  }
  return value;
}
