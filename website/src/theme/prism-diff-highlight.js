// From https://github.com/facebook/docusaurus/issues/3318#issuecomment-2065547731

const LANGUAGE_REGEX = /^diff-([\w-]+)/i;

const tokenStreamToString = (tokenStream) => {
  const result = [];
  const stack = [tokenStream];

  while (stack.length > 0) {
    const item = stack.pop();

    if (typeof item === "string") {
      result.push(item);
    } else if (Array.isArray(item)) {
      for (let i = item.length - 1; i >= 0; i--) {
        stack.push(item[i]);
      }
    } else {
      // If it's a Token, convert it to a string and push it
      stack.push(item.content);
    }
  }

  return result.join("");
};

export function diffHighlight(Prism) {
  Prism.hooks.add("after-tokenize", function (env) {
    let diffLanguage;
    let diffGrammar;
    const language = env.language;
    if (language !== "diff") {
      const langMatch = LANGUAGE_REGEX.exec(language);
      if (!langMatch) {
        return; // not a language specific diff
      }

      diffLanguage = langMatch[1];
      diffGrammar = Prism.languages[diffLanguage];
      if (!diffGrammar) {
        console.error(
          "prism-diff-highlight:",
          `You need to add language '${diffLanguage}' to use '${language}'`,
        );
        return;
      }
    } else return;

    const newTokens = [];
    env.tokens.forEach((token) => {
      if (typeof token === "string") {
        newTokens.push(...Prism.tokenize(token, diffGrammar));
      } else if (token.type === "unchanged") {
        newTokens.push(
          ...Prism.tokenize(tokenStreamToString(token), diffGrammar),
        );
      } else if (["deleted-sign", "inserted-sign"].includes(token.type)) {
        token.alias = [
          token.type === "deleted-sign"
            ? "diff-highlight-deleted"
            : "diff-highlight-inserted",
        ];
        // diff parser always return "deleted" and "inserted" lines with content of type array
        if (token.content.length > 1) {
          const newTokenContent = [];
          // preserve prefixes and don't parse them again
          // subTokens from diff parser are of type Token
          token.content.forEach((subToken) => {
            if (subToken.type === "prefix") {
              newTokenContent.push(subToken);
            } else {
              newTokenContent.push(
                ...Prism.tokenize(tokenStreamToString(subToken), diffGrammar),
              );
            }
          });
          token.content = newTokenContent;
        }
        newTokens.push(token);
      } else if (token.type === "coord") {
        newTokens.push(token);
      }
    });
    console.log(newTokens);
    env.tokens = newTokens;
  });
}
