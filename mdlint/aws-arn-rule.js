const awsAccountId = "1234567890";

module.exports = {
  names: ["AWS-ARN-RULE"],
  description: "Check if AWS ARNs use the correct sample account ID",
  tags: ["aws", "arn"],
  function: function aws_arn_rule(params, onError) {
    const arnRegex = /arn:aws:([a-zA-Z0-9-]+):([a-zA-Z0-9-]+)?:([0-9]+):/;

    params.tokens.filter(function filterToken(token) {
      let matches;

      if (["paragraph_open"].indexOf(token.type) > -1) {
        const paragraph = token.line.replace(/\r?\n|\r/g, "");
        matches = paragraph.match(arnRegex);
      }

      if (["fence"].indexOf(token.type) > -1) {
        const paragraph = token.content.replace(/\r?\n|\r/g, "");
        matches = paragraph.match(arnRegex);
      }

      if (matches) {
        const accountId = matches[3];
        if (accountId !== awsAccountId) {
          onError({
            lineNumber: token.lineNumber,
            detail: `AWS ARN account ID "${accountId}" does not match expected account ID "${awsAccountId}"`,
          });
        }
      }
    });
  },
};
